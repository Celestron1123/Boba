// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage'
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyAIoKIDC9TeSw_j6k2fnDn5d0hoL1gNBjY",
  authDomain: "boba-b0c9c.firebaseapp.com",
  projectId: "boba-b0c9c",
  storageBucket: "boba-b0c9c.firebasestorage.app",
  messagingSenderId: "644751782553",
  appId: "1:644751782553:web:b2dd167249a18116ce3e08"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export const db = getFirestore(app) 
export const storage = getStorage(app)