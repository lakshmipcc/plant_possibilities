const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { logger } = require("firebase-functions");

exports.identifyPlant = onCall({ secrets: ["GEMINI_API_KEY"], invoker: "public" }, async (request) => {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) throw new HttpsError('failed-precondition', 'API Key missing.');

    const imageBase64 = request.data.image;
    if (!imageBase64) throw new HttpsError('invalid-argument', 'Image argument missing.');

    // SWITCHING TO RAW REST API (Bypassing SDK completely)
    // The SDK was failing with 404s, but raw listModels worked. 
    // So we use raw generateContent.

    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=${apiKey}`;



    const payload = {
        contents: [{
            parts: [
                { text: 'Identify this plant. Return ONLY JSON: {"commonName": "...", "scientificName": "...", "funFact": "..."}' },
                { inline_data: { mime_type: "image/jpeg", data: imageBase64 } }
            ]
        }]
    };

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        const data = await response.json();

        if (!response.ok) {
            logger.error("RAW API ERROR:", data);
            throw new Error(`Gemini API Error: ${data.error ? data.error.message : JSON.stringify(data)}`);
        }

        // Parse Response
        const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!text) throw new Error("No text returned from Gemini");

        // CLEAN JSON
        let cleanJson = text.trim();
        const jsonMatch = cleanJson.match(/\{[\s\S]*\}/);
        if (jsonMatch) cleanJson = jsonMatch[0];

        return JSON.parse(cleanJson);

    } catch (error) {
        logger.error("GENERATE ERROR:", error);
        throw new HttpsError('internal', `Plant identification failed: ${error.message}`);
    }
});
