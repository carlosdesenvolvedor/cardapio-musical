import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { AccessToken } from "livekit-server-sdk";

admin.initializeApp();

/**
 * Generates a LiveKit access token for a specific room and participant.
 * Expects: { roomName: string, participantName: string }
 */
export const getLiveKitToken = onCall(async (request) => {
    // Check if user is authenticated via Firebase
    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { roomName, participantName } = request.data;

    if (!roomName || !participantName) {
        throw new HttpsError(
            "invalid-argument",
            "roomName and participantName are required."
        );
    }

    // Retrieve credentials from environment variables or secrets
    // In production, use Firebase Secrets or process.env
    const apiKey = process.env.LIVEKIT_API_KEY || "APIu7qNFA2Uuk95";
    const apiSecret = process.env.LIVEKIT_API_SECRET || "0UosM5ydHhRzMy87MLD3UUZGKRtk712e99emuIimxnfB";

    try {
        const at = new AccessToken(apiKey, apiSecret, {
            identity: participantName,
        });

        at.addGrant({
            roomJoin: true,
            room: roomName,
            canPublish: true,
            canSubscribe: true,
            canPublishData: true,
        });

        return {
            token: await at.toJwt(),
            serverUrl: process.env.LIVEKIT_URL || "wss://playart-0406wsow.livekit.cloud",
        };
    } catch (error) {
        console.error("Error generating token:", error);
        throw new HttpsError(
            "internal",
            "Error generating LiveKit token"
        );
    }
});
