const { onCall, HttpsError } = require("firebase-functions/v2/https");

// Shared cache for available models to avoid repeated API calls on every request
let rankedModelsCache = [];
let lastCacheUpdate = 0;
const CACHE_DURATION = 24 * 60 * 60 * 1000; // 24 hours

/**
 * Fetches and ranks models available to the API key
 */
async function getRankedModels(apiKey) {
    try {
        console.log('DEBUG: [Discovery] Fetching available models...');
        const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`);
        const data = await response.json();

        if (!data.models) {
            console.error('DEBUG: [Discovery] Failed to fetch models:', data);
            return [];
        }

        return data.models
            .filter(m => m.supportedGenerationMethods.includes('generateContent'))
            .sort((a, b) => {
                const getScore = (m) => {
                    let s = 0;
                    const n = m.name.toLowerCase();
                    if (n.includes('flash')) s += 50;
                    if (n.includes('2.0') || n.includes('2.5')) s += 30;
                    if (n.includes('lite')) s += 10;
                    if (n.includes('exp') || n.includes('preview')) s -= 20;
                    return s;
                };
                return getScore(b) - getScore(a);
            });
    } catch (err) {
        console.error('DEBUG: [Discovery] Error fetching models:', err);
        return [];
    }
}

exports.identifyPlant = onCall({ secrets: ["GEMINI_API_KEY"], invoker: "public" }, async (request) => {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) throw new HttpsError('failed-precondition', 'API Key missing.');

    const imageBase64 = request.data.image;
    if (!imageBase64) throw new HttpsError('invalid-argument', 'Image argument missing.');

    // 1. Discovery & Caching
    const now = Date.now();
    if (rankedModelsCache.length === 0 || (now - lastCacheUpdate) > CACHE_DURATION) {
        rankedModelsCache = await getRankedModels(apiKey);
        lastCacheUpdate = now;
        console.log(`DEBUG: [Discovery] Cached ${rankedModelsCache.length} prioritized models.`);
    }

    // 2. Fallback execution loop
    let lastError = null;
    const modelsToTry = rankedModelsCache.length > 0 ? rankedModelsCache.slice(0, 5) : [{ name: 'models/gemini-2.0-flash-lite' }];

    for (const model of modelsToTry) {
        try {
            console.log(`DEBUG: [Negotiator] Trying model: ${model.name}`);
            const url = `https://generativelanguage.googleapis.com/v1beta/${model.name.includes('/') ? model.name : 'models/' + model.name}:generateContent?key=${apiKey}`;

            const response = await fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    contents: [{
                        parts: [
                            { text: "Identify this plant and return ONLY a JSON object with: \"commonName\", \"scientificName\", and \"funFact\". Focus on accuracy." },
                            { inline_data: { mime_type: "image/jpeg", data: imageBase64 } }
                        ]
                    }],
                    generationConfig: {
                        temperature: 0.1,
                        maxOutputTokens: 1024,
                    }
                })
            });

            const result = await response.json();

            if (response.status === 429 || response.status === 404 || response.status === 410) {
                console.warn(`DEBUG: [Negotiator] ${model.name} failed with ${response.status}. Skipping...`);
                if (response.status === 404 || response.status === 410) rankedModelsCache = [];
                continue;
            }

            if (!response.ok) throw new Error(result.error?.message || `API Error (${response.status})`);

            // Parse Response
            const text = result.candidates?.[0]?.content?.parts?.[0]?.text;
            if (!text) throw new Error("No text returned from Gemini");

            let cleanJson = text.trim();
            const jsonMatch = cleanJson.match(/\{[\s\S]*\}/);
            if (jsonMatch) cleanJson = jsonMatch[0];

            console.log(`DEBUG: [Negotiator] Success with ${model.name}`);
            return JSON.parse(cleanJson);

        } catch (err) {
            console.error(`DEBUG: [Negotiator] Error with ${model.name}:`, err.message);
            lastError = err;
        }
    }

    throw new HttpsError('unavailable', `Identification failed across all models. Last Error: ${lastError?.message}`);
});
