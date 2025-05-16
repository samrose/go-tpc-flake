-- Supabase Load Test
-- This test suite exercises various aspects of the Supabase schema

-- 1. Auth Schema Tests
-- Test user creation and authentication flows
DO $$
DECLARE
    test_user_id uuid;
    test_instance_id uuid;
BEGIN
    -- Create test instance
    INSERT INTO auth.instances (id, uuid, raw_base_config, created_at, updated_at)
    VALUES (
        gen_random_uuid(),
        gen_random_uuid(),
        '{"site_url": "http://localhost:3000"}',
        NOW(),
        NOW()
    ) RETURNING id INTO test_instance_id;

    -- Create test users
    FOR i IN 1..100 LOOP
        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            created_at,
            updated_at
        ) VALUES (
            test_instance_id,
            gen_random_uuid(),
            'authenticated',
            'authenticated',
            'test_user_' || i || '@example.com',
            crypt('password123', gen_salt('bf')),
            NOW(),
            NOW()
        ) RETURNING id INTO test_user_id;

        -- Create refresh tokens
        INSERT INTO auth.refresh_tokens (
            instance_id,
            token,
            user_id,
            created_at,
            updated_at
        ) VALUES (
            test_instance_id,
            'test_token_' || i,
            test_user_id::text,
            NOW(),
            NOW()
        );

        -- Create audit log entries
        INSERT INTO auth.audit_log_entries (
            instance_id,
            id,
            payload,
            created_at
        ) VALUES (
            test_instance_id,
            gen_random_uuid(),
            jsonb_build_object(
                'action', 'user_signup',
                'user_id', test_user_id,
                'email', 'test_user_' || i || '@example.com'
            ),
            NOW()
        );
    END LOOP;
END $$;

-- 2. Storage Schema Tests
-- Test bucket and object operations
DO $$
DECLARE
    test_bucket_id text;
    test_user_id uuid;
BEGIN
    -- Get a test user
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;

    -- Create test buckets
    FOR i IN 1..10 LOOP
        INSERT INTO storage.buckets (
            id,
            name,
            owner,
            created_at,
            updated_at
        ) VALUES (
            'test-bucket-' || i,
            'Test Bucket ' || i,
            test_user_id,
            NOW(),
            NOW()
        ) RETURNING id INTO test_bucket_id;

        -- Create test objects in each bucket
        FOR j IN 1..100 LOOP
            INSERT INTO storage.objects (
                bucket_id,
                name,
                owner,
                metadata
            ) VALUES (
                test_bucket_id,
                'test-object-' || j || '.txt',
                test_user_id,
                jsonb_build_object(
                    'size', 1024,
                    'mimeType', 'text/plain',
                    'cacheControl', 'public, max-age=31536000'
                )
            );
        END LOOP;
    END LOOP;
END $$;

-- 3. Complex Queries Tests

-- Test auth user queries with joins
SELECT 
    u.email,
    COUNT(r.id) as refresh_token_count,
    COUNT(a.id) as audit_log_count
FROM auth.users u
LEFT JOIN auth.refresh_tokens r ON u.id::text = r.user_id
LEFT JOIN auth.audit_log_entries a ON u.instance_id = a.instance_id
GROUP BY u.email
ORDER BY refresh_token_count DESC
LIMIT 10;

-- Test storage queries with metadata
SELECT 
    b.name as bucket_name,
    COUNT(o.id) as object_count,
    AVG((o.metadata->>'size')::int) as avg_object_size,
    MAX(o.created_at) as latest_object
FROM storage.buckets b
JOIN storage.objects o ON b.id = o.bucket_id
GROUP BY b.name
ORDER BY object_count DESC;

-- Test storage search functionality
SELECT 
    name,
    id,
    updated_at,
    created_at,
    last_accessed_at,
    metadata
FROM storage.objects
WHERE name LIKE 'test-object-%'
ORDER BY created_at DESC
LIMIT 10;

-- 4. Extension Tests

-- Test pgcrypto functions
SELECT 
    crypt('test_password', gen_salt('bf')) as encrypted_password;

-- Test uuid-ossp functions
SELECT 
    uuid_generate_v4() as new_uuid;

-- 5. Cleanup (optional, comment out if you want to keep the test data)
/*
DO $$
BEGIN
    -- Clean up storage objects
    DELETE FROM storage.objects;
    DELETE FROM storage.buckets;
    
    -- Clean up auth data
    DELETE FROM auth.refresh_tokens;
    DELETE FROM auth.audit_log_entries;
    DELETE FROM auth.users;
    DELETE FROM auth.instances;
END $$;
*/ 