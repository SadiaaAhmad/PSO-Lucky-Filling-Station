# ☁️ 24/7 Free Cloud Deployment Guide

This guide will walk you through setting up a **100% FREE 24/7 Cloud Server** and **PostgreSQL Database** for your PSO Filling Station application using **Neon.tech** and **Render.com**. 

Once completed, your mobile app will work from anywhere in the world **even when your laptop is completely powered OFF!**

---

## 📋 Overview of What We Are Doing

| Component | Cloud Platform | Free Tier Benefits | Time Needed |
| :--- | :--- | :--- | :--- |
| **Cloud Database** | [Neon.tech](https://neon.tech) | Free PostgreSQL DB (0.5 GB, 24/7 uptime) | ~2 mins |
| **FastAPI Backend** | [Render.com](https://render.com) | Free Web Service (Auto-deploys from GitHub) | ~3 mins |

---

## Step 1: Create a Free PostgreSQL Database on Neon.tech

1. Go to [https://neon.tech](https://neon.tech) in your browser and click **Sign Up** (Sign in with your GitHub account).
2. Click **Create Project**.
   - **Project Name**: `pso-fuel-station-db`
   - **Database Name**: `neondb` (Default)
   - Click **Create Project**.
3. You will see a box with your **Connection String**.
4. Copy the connection string. It will look like this:
   ```text
   postgresql://username:password@ep-cool-name-123456.us-east-2.aws.neon.tech/neondb?sslmode=require
   ```
5. Save this URL somewhere temporary (you will paste it into Render in Step 2).

---

## Step 2: Deploy your FastAPI Backend on Render.com

1. Go to [https://render.com](https://render.com) and click **Sign In** (Sign in with your GitHub account).
2. On your Render Dashboard, click **New +** (top right) and select **Web Service**.
3. Choose **Build and deploy from a Git repository**.
4. Select your repository: `SadiaaAhmad/PSO-Lucky-Filling-Station` and click **Connect**.
5. Fill in the deployment details:
   - **Name**: `pso-lucky-filling-station-api`
   - **Region**: Choose closest to Pakistan (e.g. *Singapore* or *Frankfurt*)
   - **Branch**: `main` (or `master`)
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r backend/requirements.txt`
   - **Start Command**: `uvicorn backend.app.main:app --host 0.0.0.0 --port $PORT`
   - **Instance Type**: Select **Free** ($0 / month)

6. Scroll down to **Environment Variables** and click **Add Environment Variable**:
   | Key | Value |
   | :--- | :--- |
   | `DATABASE_URL` | *(Paste your Neon connection string from Step 1)* |
   | `PYTHONPATH` | `.` |
   | `PROJECT_NAME` | `PSO Lucky Filling Station` |

7. Click **Create Web Service**.

Render will now automatically clone your repository, install dependencies, and launch your server! This takes about 2–3 minutes.

---

## Step 3: Get your Live 24/7 Backend URL

Once Render finishes deploying, you will see a green **Live** badge and your custom HTTPS URL at the top of the page:

```text
https://pso-lucky-filling-station-api.onrender.com
```

You can test it in any browser or on your phone by visiting:
`https://pso-lucky-filling-station-api.onrender.com/docs`

---

## Step 4: Connect your Mobile App to Cloud Backend

1. Make sure your GitHub changes are committed and pushed to GitHub:
   ```bash
   git add .
   git commit -m "Add 24/7 cloud deployment configuration"
   git push origin main
   ```
2. Open the app on your mobile phone.
3. In the mobile app, tap the **Server Connection Settings** icon on the main screen/app bar.
4. Enter your Render live URL:
   `https://pso-lucky-filling-station-api.onrender.com`
5. Tap **Save & Connect**.

🎉 **Congratulations!** Your mobile app is now connected to a 24/7 cloud server. You can check daily sales, fuel inventory, tank dips, and customer udhaar balances anytime, anywhere—with your laptop completely OFF!
