const request = require('supertest');
const app = require('./index');

describe('API Endpoints', () => {
  test('GET / should return welcome message', async () => {
    const response = await request(app)
      .get('/')
      .expect(200);
    
    expect(response.body.message).toBe('Welcome to DevOps Pipeline Demo');
    expect(response.body.environment).toBeDefined();
  });

  test('GET /health should return health status', async () => {
    const response = await request(app)
      .get('/health')
      .expect(200);
    
    expect(response.body.status).toBe('healthy');
    expect(response.body.uptime).toBeDefined();
  });
});
