// API Configuration
const config = {
    // Base URL for all API endpoints
    API_BASE_URL: 'http://localhost:3000',  // Change this to your production URL when deploying
    
    // API Endpoints
    API_ENDPOINTS: {
        // Auth endpoints
        LOGIN: '/api/auth/login',
        REGISTER: '/api/auth/register',
        LOGOUT: '/api/auth/logout',
        
        // User endpoints
        USER_PROFILE: '/api/user/profile',
        
        // Add more endpoints as needed
    }
};

// Helper function to get full API URL
export const getApiUrl = (endpoint) => {
    return `${config.API_BASE_URL}${endpoint}`;
};

export default config; 