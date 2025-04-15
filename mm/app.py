from flask import Flask, request, jsonify
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, firestore, messaging

app = Flask(__name__)
CORS(app)

# Initialize Firebase Admin
cred = credentials.Certificate("firebase-adminsdk.json")  # Your service account key file
firebase_admin.initialize_app(cred)
db = firestore.client()

@app.route('/subscribe', methods=['POST'])
def subscribe():
    data = request.get_json()
    user_id = data.get('user_id')
    token = data.get('token')
    
    db.collection('subscriptions').document(user_id).set({'token': token})
    return jsonify({'message': 'Subscribed successfully'}), 200

@app.route('/notify', methods=['POST'])
def notify():
    data = request.get_json()
    title = data.get('title')
    body = data.get('body')
    user_id = data.get('user_id')

    user_ref = db.collection('subscriptions').document(user_id).get()
    if user_ref.exists:
        token = user_ref.to_dict().get('token')

        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body
            ),
            token=token
        )
        response = messaging.send(message)
        return jsonify({'message': 'Notification sent', 'response': response}), 200
    else:
        return jsonify({'error': 'User not found'}), 404

if __name__ == '__main__':
    app.run(debug=True)
