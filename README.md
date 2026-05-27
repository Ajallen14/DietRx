# DietRx

DietRx is an intelligent application built with Flutter that empowers users to make safe dietary choices. By creating a personalized health profile with diagnosed conditions and allergies, users can scan food items to instantly determine if they are safe to consume. DietRx leverages AI to generate dynamic dietary rules tailored to each individual's unique health needs.

---

## About DietRx

Navigating grocery aisles with dietary restrictions shouldn't require a degree in chemistry. **DietRx** is a smart, AI-powered food scanning companion designed to take the guesswork out of eating. Whether managing a chronic condition like Diabetes or PCOS, navigating severe food allergies, or simply trying to make better health choices, DietRx acts as a personalized pocket nutritionist. By combining a highly customizable health profile with real-time AI analysis, DietRx instantly translates complex ingredient labels into simple, actionable "Safe" or "Not Safe" verdicts.

---

## The Problem We Solved

**The Pain Point:** For individuals with specific health conditions or food allergies, grocery shopping is often a stressful, time-consuming task. Food labels are notoriously difficult to decipher, filled with complex chemical names, hidden allergens, and ambiguous terminology. A single mistake in reading an ingredient list can lead to severe allergic reactions or flare-ups of chronic conditions. 

**The Solution:**
DietRx eliminates the cognitive load and anxiety of label-reading. We solved this by creating a system that:
1. **Understands the User:** Replaces generic diet advice with highly specific, individualized constraints (including edge-case conditions generated dynamically via AI).
2. **Automates the Analysis:** Scans and instantly cross-references a product's ingredient list against the user's unique profile, flagging hidden dangers that a human might miss.
3. **Empowers Confident Choices:** Transforms the complex data of nutritional labels into a clear, binary outcome, allowing users to shop safely and quickly.

---

## Features

* **Personalized Health Profiles:** Users can select from common diagnosed health conditions (e.g., Diabetes, PCOS, Celiac) and food allergies (e.g., Shellfish, Tree Nuts).
* **AI-Powered Dietary Rules:** Users can input custom, unlisted conditions or allergies, and the app seamlessly queries AI to generate and store specific dietary rules for that condition.
* **Smart Food Scanning:** Quickly scan food items to categorize them into "Safe Items" or "Not Safe Items" based on the user's active health profile.
* **Cloud Synchronization:** Built on Firebase, ensuring that user profiles, custom rules, and scan histories are securely saved and synced across devices in real-time.
* **Beautiful & Responsive UI:** A smooth, intuitive interface featuring custom animations, staggered loading, and a clean, nature-inspired color palette.

---

## Tech Stack

* **Frontend:** [Flutter](https://flutter.dev/) (Dart)
* **Backend & Database:** [Firebase Firestore](https://firebase.google.com/products/firestore)
* **Authentication:** [Firebase Auth](https://firebase.google.com/products/auth)
* **AI Integration:** Gemini API (for dynamic rule generation)

---

## Screenshots

#### Login
<img width="302" height="672" alt="image" src="https://github.com/user-attachments/assets/24c084d9-0f6e-44ee-92a2-7660994ae565" />


#### Health Profile
<img width="303" height="672" alt="image" src="https://github.com/user-attachments/assets/2a9e2b61-c182-477e-9cd7-01945d9691fe" />

#### Safe vs. Unsafe Results
<img width="1317" height="790" alt="image" src="https://github.com/user-attachments/assets/643fa850-9620-4e43-89b8-f6ea483a9add" />


#### Unknown Product
<img width="840" height="782" alt="image" src="https://github.com/user-attachments/assets/851c434a-9474-4773-90cf-57a74df11c91" />


#### Profile screen
<img width="355" height="790" alt="image" src="https://github.com/user-attachments/assets/b80aa302-2f1b-489a-903b-bf7ddfbfc604" />


#### Recipe Analyzer
<img width="928" height="782" alt="image" src="https://github.com/user-attachments/assets/e993f269-aefd-41aa-8a6b-57095e524c4f" />


---

## Getting Started

Follow these steps to set up the project locally on your machine.

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.10.0 or higher recommended)
* An IDE like [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
* A Firebase Account

### Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/Ajallen14/DietRx.git](https://github.com/Ajallen14/DietRx.git)
    cd DietRx
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup:**
    * Create a new project on the [Firebase Console](https://console.firebase.google.com/).
    * Register your Android and iOS apps.
    * Download the `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files and place them in their respective directories.
    * Enable **Firestore Database** and **Authentication** in your Firebase project.

4.  **Environment Variables (API Keys):**
    * Create a `.env` file in the root directory.
    * Add your AI API Key: `GEMINI_API_KEY=your_api_key_here`

5.  **Run the app:**
    ```bash
    flutter run
    ```

---

## How It Works

1.  **Onboarding:** The user logs in via Firebase Auth.
2.  **Profile Setup:** In the `HealthProfileScreen`, the user selects their allergies and conditions. If a condition isn't listed, typing it into the "Add other..." field triggers a backend call.
3.  **Dynamic Generation:** The `ProfileService` sends the custom condition to the AI, which generates dietary constraints and saves them directly to the `Dynamic_Rules` collection in Firestore.
4.  **Validation:** When a user scans a food item, the app cross-references the item's ingredients with both the static and dynamic rules tied to their `user_id`.

---

## 📝 License

Distributed under the MIT License. See [`LICENSE`](https://github.com/Ajallen14/DietRx/blob/main/LICENSE) for more information.

---
