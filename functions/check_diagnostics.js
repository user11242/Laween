const admin = require("firebase-admin");

// Initialize using the default credentials if possible, or application default
admin.initializeApp({
    projectId: "laween-f7c2d" // From google-services
});

async function checkDiagnostics() {
    console.log("Fetching recent users...");
    const snapshot = await admin.firestore().collection("users")
        .orderBy("lastTokenUpdate", "desc")
        .limit(10)
        .get();

    if (snapshot.empty) {
        console.log("No recent users found.");
        return;
    }

    snapshot.forEach(doc => {
        const data = doc.data();
        console.log(`\n--- User: ${data.name || doc.id} ---`);
        console.log(`Last Token Update: ${data.lastTokenUpdate ? data.lastTokenUpdate.toDate() : 'N/A'}`);
        if (data.tokenDiagnostics) {
            console.log("Diagnostics:");
            console.log(JSON.stringify(data.tokenDiagnostics, null, 2));
        } else {
            console.log("No token diagnostics found.");
        }
    });
}

checkDiagnostics().catch(console.error);
