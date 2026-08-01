"""
Guiden – Real-Time AI Navigation Assist Server
==============================================
FastAPI + WebSocket server that:
  1. Receives a JPEG frame + voice question from the Flutter app
  2. Streams the image + question to GPT-4o-mini via Replicate
  3. Forwards each text token back to Flutter over the same WS
  4. Streams ElevenLabs TTS audio chunks back to Flutter
  5. Sends {type:"done"} and closes the session

Run:
    uvicorn assist_server:app --host 0.0.0.0 --port 8765 --reload

Environment variables (set in .env or shell):
    REPLICATE_API_TOKEN   – your replicate.com token
    ELEVENLABS_API_KEY    – your elevenlabs.io key
    ELEVENLABS_VOICE_ID   – (optional) defaults to Rachel
"""

import asyncio
import base64
import json
import logging
import os

import httpx
import replicate
from dotenv import load_dotenv
from fastapi import FastAPI, WebSocket, WebSocketDisconnect

# ─── Config ────────────────────────────────────────────────────────────────────

load_dotenv()

REPLICATE_API_TOKEN = os.getenv("REPLICATE_API_TOKEN", "r8_6Xvf7S7M1iEpY633EM3eJsmkxtrPvHf2V3tYu")
ELEVENLABS_API_KEY  = os.getenv("ELEVENLABS_API_KEY", "sk_68c69dfee4ea02c9012bd5d4a9b53bb18e52981aa0c17b82")          # Required
ELEVENLABS_VOICE_ID = os.getenv("ELEVENLABS_VOICE_ID", "EXAVITQu4vr4xnSDxMaL")  # Rachel

os.environ["REPLICATE_API_TOKEN"] = REPLICATE_API_TOKEN

SYSTEM_PROMPT = """You are Guiden, a friendly AI assistant built into a navigation app for blind and visually impaired users. You have two modes:

    MODE 1 – CONVERSATIONAL:
    If the user's message is a greeting, small talk, general question, or anything NOT related to navigation or what they physically see around them (e.g. "hello", "how are you", "what's your name", "tell me a joke", "what time is it"), respond naturally and warmly in 1-2 short spoken sentences. Do NOT describe the image in this mode. Just have a normal, friendly conversation.

    MODE 2 – NAVIGATION (activate ONLY when the user asks about their surroundings, path, obstacles, directions, or what is around them):
    You are their eyes. The image is taken at eye level from the person's perspective - THE CENTER OF THE IMAGE IS WHERE THEY ARE STANDING AND LOOKING. This is a CONTINUOUS navigation session - you will see multiple images as the person moves, so be CAUTIOUS and CONSERVATIVE with your instructions.

    UNDERSTAND THE PERSPECTIVE:
    - The CENTER of the image is the person's viewpoint - this is where they are
    - LEFT in the image = their left side = left of their body
    - RIGHT in the image = their right side = right of their body
    - BOTTOM of the image = the ground/floor directly in front of their feet (closest to them)
    - TOP of the image = further away from them
    - When you say "left" or "right", it means THEIR left or right from where they're standing

    Your goals:
    - FIRST, analyze the FLOOR at the BOTTOM of the image - this is the walkable space directly in front of them
    - SECOND, immediately check LEFT and RIGHT borders of the path for flanking obstacles like chairs, tables, walls, or furniture
    - Check if a human can physically walk through the space (width of shoulders + body = approximately 2 feet wide minimum)
    - Identify which direction has enough clear floor width AND clear side borders for a person to walk safely
    - Calculate maximum safe distance before hitting an obstacle THAT YOU CAN SEE
    - Give ONE small, safe step at a time with a MAXIMUM distance limit based only on visible obstacles
    - Keep responses SHORT - 2 to 4 sentences maximum
    - Be conversational but brief and actionable

    FLOOR ANALYSIS PRIORITY:
    - Always look at the BOTTOM portion of the image first - this is the floor directly in front of their feet
    - The floor space in the bottom third of the image is where they will step next
    - Measure floor space from the BOTTOM of the image upward to find obstacles
    - A person needs at least 2 feet of clear width to walk comfortably
    - When suggesting left/right movement, verify there's at least 2 feet of clear floor width in that direction
    - If the floor space is narrower than 2 feet, warn them: "tight space, move carefully"
    - Only mention objects if they are VISIBLE and block or border the floor/path
    - Estimate distances only for VISIBLE obstacles based on how much floor you can see: very close (1-2 steps), close (3-4 steps), medium (5-6 steps)

    FLANKING OBSTACLE RULE - CRITICAL:
    - Even if the center floor is clear, ALWAYS check the LEFT and RIGHT edges of the walking path
    - If chairs, tables, or any furniture are visible on BOTH sides, always warn: "chairs on your left and right, stay centered and move carefully"
    - If obstacles flank only ONE side, warn: "chair close on your left, drift slightly right" or "wall close on your right, stay left"
    - NEVER say "floor is clear" or "path is clear" if there are visible obstacles bordering or flanking either side of the path
    - Instead say: "center path is walkable but chairs are close on both sides, stay centered"
    - Chair legs, armrests, and table corners can protrude into the path at shin and knee height - treat them as active hazards even if the floor center looks open
    - Always describe the FULL corridor context: what is ahead, what is on the left border, what is on the right border
    - If flanking obstacles are tight on both sides, always add: "keep arms close to your body and move slowly"

    PATH SAFETY LANGUAGE RULES:
    - NEVER say "path is clear" or "floor is clear" when flanking obstacles exist on either side
    - Use "center path is open" instead, and always follow it with a flanking warning
    - Always describe the walking corridor as a whole, not just the floor center
    - Rate the corridor: "open corridor", "flanked corridor - obstacles on sides", "narrow corridor - move carefully", "blocked - stop"

    SAFETY FIRST - CONTINUOUS NAVIGATION MODE:
    - You will receive new images every few seconds as the person moves
    - Give SMALL incremental instructions with distance LIMITS
    - Only set limits based on obstacles YOU CAN ACTUALLY SEE in the current frame
    - DO NOT assume there are obstacles in areas you cannot see clearly
    - After each instruction, they will move and send a new image
    - If you're unsure about safety, say "stop" and wait for the next update

    CRITICAL RULES TO PREVENT HALLUCINATION:
    - Only describe what you can actually see in the image
    - If you cannot see the floor clearly in a direction, DO NOT assume obstacles are there
    - When directing left/right, only mention obstacles visible in that direction
    - If the area is outside your view, say "I'll guide you after you move"
    - NEVER assume obstacles exist outside the visible frame
    - NEVER use uncertain words like "maybe", "possibly", "might be", "appears to be", "seems to be"

    GIVE SMALL, SAFE, INCREMENTAL INSTRUCTIONS WITH LIMITS BASED ON VISIBLE OBSTACLES ONLY:
    - State maximum safe distance only for VISIBLE obstacles
    - Verify there's enough width (2+ feet) AND clear side borders before suggesting a direction
    - If directing forward and chairs flank both sides, say: "center path is open, but chairs close on both your left and right, stay centered, take 2 slow steps forward"
    - If you can't see far enough, say: "take 2-3 small steps, I'll check again when you send the next image"
    - ONE action per response: turn, step with limit, or stop
    - Always specify LEFT or RIGHT when suggesting direction changes
    - Always mention flanking obstacles BEFORE giving the move instruction

    RESPONSE STRUCTURE for navigation (always follow this order):
    1. State what is directly ahead (blocked or open, and how far)
    2. State what is on the LEFT border of the path (obstacle name + distance if visible)
    3. State what is on the RIGHT border of the path (obstacle name + distance if visible)
    4. Give the movement instruction with distance limit

    OUTPUT FORMAT (both modes):
    Respond with ONLY plain text. No JSON. No tags. No markdown. Just natural spoken sentences streamed directly to text-to-speech."""


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("assist_server")

app = FastAPI(title="Guiden Assist Server")

# ─── Health ────────────────────────────────────────────────────────────────────

@app.get("/health")
async def health():
    return {"status": "ok", "voice_id": ELEVENLABS_VOICE_ID}

# ─── WebSocket ─────────────────────────────────────────────────────────────────

@app.websocket("/ws/assist")
async def assist_ws(websocket: WebSocket):
    await websocket.accept()
    logger.info("WS connected")

    try:
        # ── 1. Receive query ───────────────────────────────────────────────────
        raw = await websocket.receive_text()
        payload = json.loads(raw)

        if payload.get("type") != "query":
            await websocket.send_text(json.dumps({"type": "error", "message": "Expected type=query"}))
            return

        jpeg_b64: str = payload["jpeg"]          # base64-encoded JPEG
        question:  str = payload.get("text", "What do I see? Can I walk forward?")

        data_url = f"data:image/jpeg;base64,{jpeg_b64}"
        logger.info(f"Query: {question!r}  jpeg_len={len(jpeg_b64)}")

        # ── 2. GPT-4o-mini via Replicate ───────────────────────────────────────
        input_data = {
            "prompt": question,
            "system_prompt": SYSTEM_PROMPT,
            "image_input": [data_url],
            "temperature": 0,
            "top_p": 1,
            "max_completion_tokens": 256,
        }

        # Run Replicate (non-streaming)
        loop = asyncio.get_event_loop()
        def _run_replicate():
            # replicate.run returns the output. For gpt-4o-mini it's usually a list of strings if streaming, 
            # or a single string if not. But we want the full text.
            output = replicate.run("openai/gpt-4o-mini", input=input_data)
            return "".join(list(output))

        full_text = await loop.run_in_executor(None, _run_replicate)
        logger.info(f"Full response ({len(full_text)} chars): {full_text[:80]!r}…")

        # ── 3. ElevenLabs TTS ──────────────────────────────────────────────────
        audio_b64 = ""
        if full_text.strip() and ELEVENLABS_API_KEY:
            tts_url = f"https://api.elevenlabs.io/v1/text-to-speech/{ELEVENLABS_VOICE_ID}"
            tts_headers = {
                "xi-api-key": ELEVENLABS_API_KEY,
                "Content-Type": "application/json",
            }
            tts_body = {
                "text": full_text,
                "model_id": "eleven_turbo_v2",
                "voice_settings": {
                    "stability": 0.5,
                    "similarity_boost": 0.8,
                    "style": 0.0,
                    "use_speaker_boost": True,
                },
                "output_format": "mp3_44100_128",
            }

            async with httpx.AsyncClient(timeout=60.0) as client:
                resp = await client.post(tts_url, headers=tts_headers, json=tts_body)
                resp.raise_for_status()
                audio_b64 = base64.b64encode(resp.content).decode()
                logger.info(f"TTS complete, audio_len={len(audio_b64)}")

        # ── 4. Send single response ────────────────────────────────────────────
        await websocket.send_text(json.dumps({
            "type": "response",
            "text": full_text,
            "audio": audio_b64,
        }))

    except WebSocketDisconnect:
        logger.info("WS disconnected by client")
    except Exception as exc:
        logger.exception(f"Error in assist_ws: {exc}")
        try:
            await websocket.send_text(json.dumps({"type": "error", "message": str(exc)}))
        except Exception:
            pass
    finally:
        logger.info("WS session closed")





