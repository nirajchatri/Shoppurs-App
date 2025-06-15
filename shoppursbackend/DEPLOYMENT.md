# Anwar Food Backend - Render Deployment Guide

## Prerequisites
1. A Render account (sign up at https://render.com)
2. Your code pushed to a Git repository (GitHub, GitLab, or Bitbucket)
3. A MySQL database (you can use PlanetScale, Railway, or any MySQL hosting service)

## Deployment Steps

### 1. Prepare Your Database
- Set up a MySQL database on a cloud provider (PlanetScale, Railway, etc.)
- Import your database schema using the SQL files in this project
- Note down the connection details (host, username, password, database name)

### 2. Deploy to Render

#### Option A: Using the Render Dashboard
1. Go to https://render.com and sign in
2. Click "New +" and select "Web Service"
3. Connect your Git repository
4. Configure the service:
   - **Name**: `anwarfood-backend`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Free (or paid for better performance)

#### Option B: Using render.yaml (Recommended)
1. Push this code to your Git repository
2. Go to Render dashboard
3. Click "New +" and select "Blueprint"
4. Connect your repository and select the `render.yaml` file

### 3. Set Environment Variables
In your Render service settings, add these environment variables:

```
DB_HOST=your_database_host
DB_USER=your_database_user  
DB_PASSWORD=your_database_password
DB_NAME=shoppurs
JWT_SECRET=your_secure_jwt_secret_key
NODE_ENV=production
PORT=10000
```

### 4. Database Setup
Make sure to run these SQL files on your database:
- `missing_tables.sql`
- `customer_address_table.sql`
- `order_tables.sql`

### 5. Test Your Deployment
Once deployed, your API will be available at:
`https://your-service-name.onrender.com`

Test the endpoints:
- GET `/api/products` - Should return product list
- POST `/api/auth/login` - Should handle user login

## Important Notes
- The free tier on Render may have cold starts (delays when not used)
- Make sure your database allows connections from Render's IP ranges
- Keep your JWT_SECRET secure and never commit it to version control
- Monitor your application logs in the Render dashboard

## Troubleshooting
- Check the Render logs if deployment fails
- Ensure all environment variables are set correctly
- Verify database connectivity
- Make sure your database schema is properly imported 