const db = require('./db');

const initDatabase = async () => {
  try {
    console.log('Connecting to database to initialize and migrate tables...');

    // 1. Create/Migrate Users table
    await db.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE,
        mobile VARCHAR(20) UNIQUE,
        mobile_verified BOOLEAN DEFAULT FALSE,
        password_hash VARCHAR(255),
        role VARCHAR(50) DEFAULT 'OFFICER',
        status VARCHAR(50) DEFAULT 'ACTIVE',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Ensure columns exist on already-existing tables
    await db.query(`
      ALTER TABLE users ADD COLUMN IF NOT EXISTS mobile VARCHAR(20) UNIQUE;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS mobile_verified BOOLEAN DEFAULT FALSE;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'ACTIVE';
      ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
      ALTER TABLE users ALTER COLUMN email DROP NOT NULL;
      ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;
    `);

    // 2. Create OTP Verifications table
    await db.query(`
      CREATE TABLE IF NOT EXISTS otp_verifications (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        mobile VARCHAR(20) NOT NULL,
        otp_hash VARCHAR(255) NOT NULL,
        attempts INT DEFAULT 0,
        verified BOOLEAN DEFAULT FALSE,
        expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_otp_mobile ON otp_verifications(mobile);
    `);

    // 3. Create Documents table
    await db.query(`
      CREATE TABLE IF NOT EXISTS documents (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        document_type VARCHAR(50) NOT NULL,
        status VARCHAR(50) DEFAULT 'UPLOADED',
        review_decision VARCHAR(50) DEFAULT 'PENDING',
        file_data BYTEA,
        file_content_type VARCHAR(100),
        selfie_data BYTEA,
        selfie_content_type VARCHAR(100),
        uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // 4. Create Screenings & Verification Pipeline tables
    await db.query(`
      CREATE TABLE IF NOT EXISTS screenings (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID,
        selected_document_type VARCHAR(50) NOT NULL,
        detected_document_type VARCHAR(50) NOT NULL,
        status VARCHAR(50) NOT NULL DEFAULT 'PROCESSING',
        risk_score INT DEFAULT 0,
        risk_level VARCHAR(20) DEFAULT 'LOW',
        execution_duration_ms INT DEFAULT 0,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_screenings_user ON screenings(user_id);
      CREATE INDEX IF NOT EXISTS idx_screenings_status ON screenings(status);

      CREATE TABLE IF NOT EXISTS document_analyses (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        screening_id UUID REFERENCES screenings(id) ON DELETE CASCADE,
        ocr_data JSONB,
        mrz_data JSONB,
        qr_data JSONB,
        tamper_data JSONB,
        authoritative_data JSONB,
        risk_reasons JSONB,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_analyses_screening ON document_analyses(screening_id);

      CREATE TABLE IF NOT EXISTS audit_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        officer_id UUID,
        action VARCHAR(100) NOT NULL,
        resource_id VARCHAR(100),
        ip_address VARCHAR(50),
        details JSONB,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // 4. Seed/Upsert default Officer accounts in Supabase PostgreSQL
    const bcrypt = require('bcryptjs');
    const hash123456 = await bcrypt.hash('123456', 10);
    const hashOfficer123 = await bcrypt.hash('officer123', 10);
    const hashPassword123 = await bcrypt.hash('password123', 10);

    // Primary requested officer
    await db.query(`
      INSERT INTO users (name, email, mobile, mobile_verified, password_hash, role, status)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (email) 
      DO UPDATE SET password_hash = EXCLUDED.password_hash, role = 'OFFICER', mobile_verified = true;
    `, ['Chief Officer', 'officer@gmail.com', '+919876543210', true, hash123456, 'OFFICER', 'ACTIVE']);

    // Quick Test buttons accounts
    await db.query(`
      INSERT INTO users (name, email, mobile, mobile_verified, password_hash, role, status)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (email) 
      DO UPDATE SET password_hash = EXCLUDED.password_hash, role = 'OFFICER', mobile_verified = true;
    `, ['Test Officer', 'officer@test.com', '+919876543211', true, hash123456, 'OFFICER', 'ACTIVE']);

    await db.query(`
      INSERT INTO users (name, email, mobile, mobile_verified, password_hash, role, status)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (email) 
      DO UPDATE SET password_hash = EXCLUDED.password_hash, role = 'OFFICER', mobile_verified = true;
    `, ['Agency Officer', 'officer@agency.gov.in', '+919876543212', true, hashPassword123, 'OFFICER', 'ACTIVE']);

    console.log('Officer accounts seeded in Supabase:');
    console.log(' - officer@gmail.com / 123456');
    console.log(' - officer@test.com / 123456');
    console.log(' - officer@agency.gov.in / password123');
    console.log('Database tables and seed updated successfully in Supabase!');
  } catch (error) {
    console.error('Error creating database tables:', error);
  } finally {
    process.exit();
  }
};

initDatabase();
