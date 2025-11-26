Muuguzi – AI-Powered Dementia Support & Caregiver Matching System

Muuguzi is an intelligent mobile and backend system that supports dementia patients, caregivers, and nursing homes through AI-powered predictions, caregiver matching, reminders, and patient management.
The system integrates a Flutter mobile app, a Flask backend, and Firebase Firestore to deliver a complete end-to-end solution.

🚀 Features
🧠 1. ML-Based Survival Prediction

Uses:

MMSE score (0–30)

FAST stage (1–7)

Comorbidities

Neurological symptoms

Respiratory issues

Demographics

Model outputs:

Survival score

Survival category (High / Medium / Low)

Personalized recommendations

👩‍⚕️ 2. Caregiver Matching

Matches patients with caregivers based on:

Location

Preferred gender

Preferred availability (day/night)

Caregiver qualifications

Supports:

Private caregivers

Nursing home caregivers

Admin caregiver management

📅 3. Smart Reminder System

Add medical or appointment reminders

Calendar view

Local notifications

Firestore sync

👤 4. Patient Module

Login & Sign Up

View prediction history

Submit caregiver matching request

Manage reminders

View assigned caregiver

🧑‍⚕️ 5. Caregiver Module

Private caregivers can:

Update work info

View matched patients

Manage profile

Nursing homes can:

Add caregivers

Edit caregivers

View matched patients

🧩 System Architecture
Frontend

Flutter (Dart)

Supports Android, iOS, Web, Windows, macOS

Backend

Flask (Python) REST API

Endpoints:

/api/predict_survival

/api/match_caregivers

/api/admin/caregivers

Machine Learning

Scikit-learn models

Trained using:

Cleaned dementia dataset

Caregiver–patient matching data

Includes model validation & testing scripts

Database

Firebase Firestore

Collections:

patients

caregivers

reminders

predictions

matches

admin

📂 Project Structure
/frontend_flutter/
    ├── lib/
    ├── android/
    ├── ios/
    ├── web/
    ├── pubspec.yaml

/backend_flask/
    ├── app.py
    ├── models/
    ├── train_model.py
    ├── saved_models/
    ├── requirements.txt

⚙️ Running the Project
1. Run the Backend (Flask)
cd backend_flask
pip install -r requirements.txt
python app.py


Server runs on:

http://127.0.0.1:5000

2. Run the Flutter App
cd frontend_flutter
flutter pub get
flutter run


Make sure to update:

lib/services/api_service.dart


Set:

static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator


For physical devices, replace with your LAN IP.

📊 Model Training

To retrain the AI model:

python train_model.py


Outputs:

survival_model.pkl

scaler.pkl

matching_model.pkl

Stored in /saved_models.

🧪 Model Evaluation

Run:

python evaluate_model.py


Displays:

Accuracy

Confusion matrix

Test performance

🔐 Authentication

Uses Firebase Authentication:

Email + password for patients

Email + password for caregivers

Admin login for nursing homes

🔧 Tech Stack
Component	Technology
Frontend	Flutter
Backend	Flask
Models	scikit-learn
Database	Firebase Firestore
Auth	Firebase Auth
Notifications	flutter_local_notifications
