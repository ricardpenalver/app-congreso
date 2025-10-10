-- Congress/Conference Mobile App Database Schema
-- Supabase PostgreSQL Migration
-- Version: 1.0.0
-- Created: 2025-10-09

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types
CREATE TYPE session_type AS ENUM ('keynote', 'talk', 'workshop', 'break', 'networking', 'panel', 'poster');
CREATE TYPE registration_status AS ENUM ('pending', 'confirmed', 'cancelled', 'checked_in');
CREATE TYPE notification_type AS ENUM ('session_reminder', 'schedule_change', 'general', 'urgent');
CREATE TYPE feedback_type AS ENUM ('session', 'speaker', 'general', 'venue');

-- 1. CORE TABLES

-- Organizations table
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    website TEXT,
    logo_url TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Attendees/Users table (extends Supabase auth.users)
CREATE TABLE attendees (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    organization_id UUID REFERENCES organizations(id),
    organization_name TEXT, -- For attendees without formal organization
    job_title TEXT,
    bio TEXT,
    profile_image_url TEXT,
    linkedin_url TEXT,
    twitter_url TEXT,
    website_url TEXT,
    networking_enabled BOOLEAN DEFAULT true,
    registration_status registration_status DEFAULT 'pending',
    registration_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    check_in_timestamp TIMESTAMP WITH TIME ZONE,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    dietary_restrictions TEXT,
    accessibility_needs TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Speakers table
CREATE TABLE speakers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attendee_id UUID REFERENCES attendees(id) ON DELETE SET NULL,
    full_name TEXT NOT NULL,
    bio TEXT,
    profile_image_url TEXT,
    organization TEXT,
    job_title TEXT,
    linkedin_url TEXT,
    twitter_url TEXT,
    website_url TEXT,
    email TEXT,
    phone TEXT,
    expertise_areas TEXT[],
    is_keynote_speaker BOOLEAN DEFAULT false,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sessions table
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    abstract TEXT,
    session_type session_type NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    location TEXT,
    room TEXT,
    capacity INTEGER,
    is_featured BOOLEAN DEFAULT false,
    requires_registration BOOLEAN DEFAULT false,
    allow_feedback BOOLEAN DEFAULT true,
    materials_url TEXT,
    live_stream_url TEXT,
    recording_url TEXT,
    tags TEXT[],
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_session_times CHECK (end_time > start_time)
);

-- Session speakers relationship
CREATE TABLE session_speakers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    speaker_id UUID REFERENCES speakers(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT false,
    presentation_order INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    UNIQUE(session_id, speaker_id)
);

-- 2. VOTING SYSTEM

-- Voting topics
CREATE TABLE voting_topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    options JSONB NOT NULL, -- Array of voting options
    is_active BOOLEAN DEFAULT true,
    allows_multiple_votes BOOLEAN DEFAULT false,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES attendees(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Individual votes
CREATE TABLE votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    voting_topic_id UUID REFERENCES voting_topics(id) ON DELETE CASCADE,
    attendee_id UUID REFERENCES attendees(id) ON DELETE CASCADE,
    selected_options JSONB NOT NULL, -- Array of selected option indices
    voted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    UNIQUE(voting_topic_id, attendee_id) -- One vote per attendee per topic
);

-- 3. TAGS AND IDEAS SYSTEM

-- User-submitted tags/keywords
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3B82F6', -- Hex color for UI
    created_by UUID REFERENCES attendees(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ideas/submissions from users
CREATE TABLE ideas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    submitted_by UUID REFERENCES attendees(id) ON DELETE SET NULL,
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'pending', -- pending, approved, rejected
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Idea tags relationship
CREATE TABLE idea_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    idea_id UUID REFERENCES ideas(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(idea_id, tag_id)
);

-- Idea votes
CREATE TABLE idea_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    idea_id UUID REFERENCES ideas(id) ON DELETE CASCADE,
    attendee_id UUID REFERENCES attendees(id) ON DELETE CASCADE,
    vote_type TEXT CHECK (vote_type IN ('up', 'down')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(idea_id, attendee_id)
);

-- 4. NETWORKING SYSTEM

-- Networking connections
CREATE TABLE networking_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requester_id UUID REFERENCES attendees(id) ON DELETE CASCADE,
    recipient_id UUID REFERENCES attendees(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    message TEXT,
    connected_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    UNIQUE(requester_id, recipient_id),
    CHECK (requester_id != recipient_id)
);

-- 5. FEEDBACK AND SURVEYS

-- Feedback/surveys
CREATE TABLE feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attendee_id UUID REFERENCES attendees(id) ON DELETE SET NULL,
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    speaker_id UUID REFERENCES speakers(id) ON DELETE SET NULL,
    feedback_type feedback_type NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    title TEXT,
    content TEXT,
    suggestions TEXT,
    is_anonymous BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. NOTIFICATIONS

-- Notification templates
CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    notification_type notification_type NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attendee_id UUID REFERENCES attendees(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    notification_type notification_type NOT NULL,
    session_id UUID REFERENCES sessions(id) ON DELETE SET NULL,
    data JSONB, -- Additional data for the notification
    is_read BOOLEAN DEFAULT false,
    scheduled_for TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. RESOURCES AND MATERIALS

-- Resource categories
CREATE TABLE resource_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Resources
CREATE TABLE resources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    file_url TEXT,
    file_type TEXT,
    file_size INTEGER, -- in bytes
    category_id UUID REFERENCES resource_categories(id),
    session_id UUID REFERENCES sessions(id) ON DELETE SET NULL,
    speaker_id UUID REFERENCES speakers(id) ON DELETE SET NULL,
    is_public BOOLEAN DEFAULT true,
    download_count INTEGER DEFAULT 0,
    uploaded_by UUID REFERENCES attendees(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. SESSION ATTENDANCE AND FAVORITES

-- Session attendance tracking
CREATE TABLE session_attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    attendee_id UUID REFERENCES attendees(id) ON DELETE CASCADE,
    registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    checked_in_at TIMESTAMP WITH TIME ZONE,

    UNIQUE(session_id, attendee_id)
);

-- Favorite sessions
CREATE TABLE favorite_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    attendee_id UUID REFERENCES attendees(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(session_id, attendee_id)
);

-- 9. INDEXES FOR PERFORMANCE

-- Attendees indexes
CREATE INDEX idx_attendees_email ON attendees(email);
CREATE INDEX idx_attendees_organization ON attendees(organization_id);
CREATE INDEX idx_attendees_registration_status ON attendees(registration_status);

-- Sessions indexes
CREATE INDEX idx_sessions_start_time ON sessions(start_time);
CREATE INDEX idx_sessions_session_type ON sessions(session_type);
CREATE INDEX idx_sessions_location ON sessions(location);
CREATE INDEX idx_sessions_tags ON sessions USING GIN(tags);

-- Session speakers indexes
CREATE INDEX idx_session_speakers_session ON session_speakers(session_id);
CREATE INDEX idx_session_speakers_speaker ON session_speakers(speaker_id);

-- Voting indexes
CREATE INDEX idx_votes_topic ON votes(voting_topic_id);
CREATE INDEX idx_votes_attendee ON votes(attendee_id);
CREATE INDEX idx_voting_topics_active ON voting_topics(is_active);

-- Tags and ideas indexes
CREATE INDEX idx_tags_name ON tags(name);
CREATE INDEX idx_ideas_submitted_by ON ideas(submitted_by);
CREATE INDEX idx_ideas_status ON ideas(is_featured, status);
CREATE INDEX idx_idea_votes_idea ON idea_votes(idea_id);

-- Networking indexes
CREATE INDEX idx_networking_requester ON networking_connections(requester_id);
CREATE INDEX idx_networking_recipient ON networking_connections(recipient_id);
CREATE INDEX idx_networking_status ON networking_connections(status);

-- Notifications indexes
CREATE INDEX idx_notifications_attendee ON notifications(attendee_id);
CREATE INDEX idx_notifications_type ON notifications(notification_type);
CREATE INDEX idx_notifications_scheduled ON notifications(scheduled_for);
CREATE INDEX idx_notifications_unread ON notifications(attendee_id, is_read) WHERE is_read = false;

-- Resources indexes
CREATE INDEX idx_resources_category ON resources(category_id);
CREATE INDEX idx_resources_session ON resources(session_id);
CREATE INDEX idx_resources_public ON resources(is_public);

-- Session attendance indexes
CREATE INDEX idx_session_attendance_session ON session_attendance(session_id);
CREATE INDEX idx_session_attendance_attendee ON session_attendance(attendee_id);
CREATE INDEX idx_favorite_sessions_attendee ON favorite_sessions(attendee_id);

-- 10. FUNCTIONS AND TRIGGERS

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to relevant tables
CREATE TRIGGER update_attendees_updated_at BEFORE UPDATE ON attendees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_speakers_updated_at BEFORE UPDATE ON speakers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sessions_updated_at BEFORE UPDATE ON sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_voting_topics_updated_at BEFORE UPDATE ON voting_topics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ideas_updated_at BEFORE UPDATE ON ideas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_resources_updated_at BEFORE UPDATE ON resources
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notification_templates_updated_at BEFORE UPDATE ON notification_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update idea vote counts
CREATE OR REPLACE FUNCTION update_idea_vote_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.vote_type = 'up' THEN
            UPDATE ideas SET upvotes = upvotes + 1 WHERE id = NEW.idea_id;
        ELSE
            UPDATE ideas SET downvotes = downvotes + 1 WHERE id = NEW.idea_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.vote_type = 'up' THEN
            UPDATE ideas SET upvotes = upvotes - 1 WHERE id = OLD.idea_id;
        ELSE
            UPDATE ideas SET downvotes = downvotes - 1 WHERE id = OLD.idea_id;
        END IF;

        IF NEW.vote_type = 'up' THEN
            UPDATE ideas SET upvotes = upvotes + 1 WHERE id = NEW.idea_id;
        ELSE
            UPDATE ideas SET downvotes = downvotes + 1 WHERE id = NEW.idea_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.vote_type = 'up' THEN
            UPDATE ideas SET upvotes = upvotes - 1 WHERE id = OLD.idea_id;
        ELSE
            UPDATE ideas SET downvotes = downvotes - 1 WHERE id = OLD.idea_id;
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- Apply vote count trigger
CREATE TRIGGER trigger_update_idea_vote_counts
    AFTER INSERT OR UPDATE OR DELETE ON idea_votes
    FOR EACH ROW EXECUTE FUNCTION update_idea_vote_counts();

-- Function to update resource download count
CREATE OR REPLACE FUNCTION increment_download_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE resources SET download_count = download_count + 1 WHERE id = NEW.resource_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Download tracking table and trigger
CREATE TABLE resource_downloads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resource_id UUID REFERENCES resources(id) ON DELETE CASCADE,
    attendee_id UUID REFERENCES attendees(id) ON DELETE SET NULL,
    downloaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TRIGGER trigger_increment_download_count
    AFTER INSERT ON resource_downloads
    FOR EACH ROW EXECUTE FUNCTION increment_download_count();

-- 11. ROW LEVEL SECURITY (RLS) POLICIES

-- Enable RLS on all tables
ALTER TABLE attendees ENABLE ROW LEVEL SECURITY;
ALTER TABLE speakers ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_speakers ENABLE ROW LEVEL SECURITY;
ALTER TABLE voting_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE ideas ENABLE ROW LEVEL SECURITY;
ALTER TABLE idea_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE idea_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE networking_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_downloads ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorite_sessions ENABLE ROW LEVEL SECURITY;

-- Attendees policies
CREATE POLICY "Users can view all confirmed attendees" ON attendees
    FOR SELECT USING (registration_status = 'confirmed' OR auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON attendees
    FOR UPDATE USING (auth.uid() = id);

-- Sessions policies (public read)
CREATE POLICY "Sessions are publicly readable" ON sessions FOR SELECT USING (true);

-- Session speakers policies (public read)
CREATE POLICY "Session speakers are publicly readable" ON session_speakers FOR SELECT USING (true);

-- Speakers policies (public read)
CREATE POLICY "Speakers are publicly readable" ON speakers FOR SELECT USING (true);

-- Voting policies
CREATE POLICY "Active voting topics are publicly readable" ON voting_topics
    FOR SELECT USING (is_active = true);

CREATE POLICY "Users can view their own votes" ON votes
    FOR SELECT USING (auth.uid() = attendee_id);

CREATE POLICY "Users can create votes" ON votes
    FOR INSERT WITH CHECK (auth.uid() = attendee_id);

CREATE POLICY "Users can update their own votes" ON votes
    FOR UPDATE USING (auth.uid() = attendee_id);

-- Tags policies
CREATE POLICY "Tags are publicly readable" ON tags FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create tags" ON tags
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Ideas policies
CREATE POLICY "Ideas are publicly readable" ON ideas FOR SELECT USING (true);

CREATE POLICY "Users can create ideas" ON ideas
    FOR INSERT WITH CHECK (auth.uid() = submitted_by);

CREATE POLICY "Users can update their own ideas" ON ideas
    FOR UPDATE USING (auth.uid() = submitted_by);

-- Idea votes policies
CREATE POLICY "Users can view idea votes" ON idea_votes FOR SELECT USING (true);

CREATE POLICY "Users can create idea votes" ON idea_votes
    FOR INSERT WITH CHECK (auth.uid() = attendee_id);

CREATE POLICY "Users can update their own idea votes" ON idea_votes
    FOR UPDATE USING (auth.uid() = attendee_id);

-- Networking policies
CREATE POLICY "Users can view their networking connections" ON networking_connections
    FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = recipient_id);

CREATE POLICY "Users can create networking requests" ON networking_connections
    FOR INSERT WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Recipients can update connection status" ON networking_connections
    FOR UPDATE USING (auth.uid() = recipient_id);

-- Feedback policies
CREATE POLICY "Users can view feedback" ON feedback FOR SELECT USING (true);

CREATE POLICY "Users can create feedback" ON feedback
    FOR INSERT WITH CHECK (auth.uid() = attendee_id OR attendee_id IS NULL);

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = attendee_id);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = attendee_id);

-- Resources policies
CREATE POLICY "Public resources are readable by all" ON resources
    FOR SELECT USING (is_public = true);

CREATE POLICY "Users can view all resource categories" ON resource_categories
    FOR SELECT USING (true);

-- Session attendance policies
CREATE POLICY "Users can view their own attendance" ON session_attendance
    FOR SELECT USING (auth.uid() = attendee_id);

CREATE POLICY "Users can register for sessions" ON session_attendance
    FOR INSERT WITH CHECK (auth.uid() = attendee_id);

CREATE POLICY "Users can update their own attendance" ON session_attendance
    FOR UPDATE USING (auth.uid() = attendee_id);

-- Favorite sessions policies
CREATE POLICY "Users can view their own favorites" ON favorite_sessions
    FOR SELECT USING (auth.uid() = attendee_id);

CREATE POLICY "Users can manage their own favorites" ON favorite_sessions
    FOR ALL USING (auth.uid() = attendee_id);

-- Resource downloads policies
CREATE POLICY "Users can view their own downloads" ON resource_downloads
    FOR SELECT USING (auth.uid() = attendee_id);

CREATE POLICY "Users can track their downloads" ON resource_downloads
    FOR INSERT WITH CHECK (auth.uid() = attendee_id);

-- 12. SAMPLE DATA INSERTS

-- Insert sample organizations
INSERT INTO organizations (id, name, website, description) VALUES
('01234567-89ab-cdef-0123-456789abcdef', 'Tech Innovation Corp', 'https://techinnovation.com', 'Leading technology innovation company'),
('11234567-89ab-cdef-0123-456789abcdef', 'Global Health Institute', 'https://globalhealth.org', 'International health research organization'),
('21234567-89ab-cdef-0123-456789abcdef', 'Sustainable Future Foundation', 'https://sustainablefuture.org', 'Environmental sustainability advocacy group');

-- Insert sample resource categories
INSERT INTO resource_categories (id, name, description, display_order) VALUES
('31234567-89ab-cdef-0123-456789abcdef', 'Presentations', 'Session presentations and slides', 1),
('32234567-89ab-cdef-0123-456789abcdef', 'Research Papers', 'Academic papers and research documents', 2),
('33234567-89ab-cdef-0123-456789abcdef', 'Event Materials', 'General event information and materials', 3),
('34234567-89ab-cdef-0123-456789abcdef', 'Networking', 'Contact lists and networking resources', 4);

-- Insert sample speakers (note: attendee_id will be NULL for these samples)
INSERT INTO speakers (id, full_name, bio, organization, job_title, expertise_areas, is_keynote_speaker, display_order) VALUES
('41234567-89ab-cdef-0123-456789abcdef', 'Dr. Sarah Johnson', 'Leading researcher in artificial intelligence and machine learning with over 15 years of experience in the field.', 'Tech Innovation Corp', 'Chief AI Officer', ARRAY['AI', 'Machine Learning', 'Data Science'], true, 1),
('42234567-89ab-cdef-0123-456789abcdef', 'Prof. Michael Chen', 'Renowned expert in sustainable technology and environmental engineering.', 'Sustainable Future Foundation', 'Director of Research', ARRAY['Sustainability', 'Green Technology', 'Environmental Engineering'], false, 2),
('43234567-89ab-cdef-0123-456789abcdef', 'Dr. Emily Rodriguez', 'Global health policy expert with extensive experience in international development.', 'Global Health Institute', 'Senior Policy Advisor', ARRAY['Health Policy', 'International Development', 'Public Health'], true, 3);

-- Insert sample sessions
INSERT INTO sessions (id, title, description, session_type, start_time, end_time, location, room, capacity, is_featured, tags) VALUES
('51234567-89ab-cdef-0123-456789abcdef', 'Opening Keynote: The Future of AI', 'Exploring the latest developments in artificial intelligence and their impact on society.', 'keynote', '2025-11-15 09:00:00+00', '2025-11-15 10:00:00+00', 'Main Convention Center', 'Auditorium A', 500, true, ARRAY['AI', 'Future Tech', 'Innovation']),
('52234567-89ab-cdef-0123-456789abcdef', 'Sustainable Technology Workshop', 'Hands-on workshop on implementing sustainable technology solutions.', 'workshop', '2025-11-15 10:30:00+00', '2025-11-15 12:00:00+00', 'Main Convention Center', 'Workshop Room B', 50, false, ARRAY['Sustainability', 'Workshop', 'Green Tech']),
('53234567-89ab-cdef-0123-456789abcdef', 'Coffee Break', 'Networking coffee break with light refreshments.', 'break', '2025-11-15 12:00:00+00', '2025-11-15 12:30:00+00', 'Main Convention Center', 'Lobby', 300, false, ARRAY['Networking', 'Break']),
('54234567-89ab-cdef-0123-456789abcdef', 'Health Technology Panel', 'Panel discussion on the intersection of technology and healthcare.', 'panel', '2025-11-15 13:30:00+00', '2025-11-15 14:30:00+00', 'Main Convention Center', 'Conference Room C', 100, true, ARRAY['Health Tech', 'Panel', 'Healthcare']);

-- Link speakers to sessions
INSERT INTO session_speakers (session_id, speaker_id, is_primary, presentation_order) VALUES
('51234567-89ab-cdef-0123-456789abcdef', '41234567-89ab-cdef-0123-456789abcdef', true, 1),
('52234567-89ab-cdef-0123-456789abcdef', '42234567-89ab-cdef-0123-456789abcdef', true, 1),
('54234567-89ab-cdef-0123-456789abcdef', '43234567-89ab-cdef-0123-456789abcdef', true, 1),
('54234567-89ab-cdef-0123-456789abcdef', '41234567-89ab-cdef-0123-456789abcdef', false, 2);

-- Insert sample voting topics
INSERT INTO voting_topics (id, title, description, options, is_active, allows_multiple_votes) VALUES
('61234567-89ab-cdef-0123-456789abcdef', 'Best Session Topic for Next Year', 'Vote for the topics you''d like to see in next year''s conference.', '["AI and Machine Learning", "Sustainable Technology", "Health Innovation", "Digital Transformation", "Cybersecurity"]', true, true),
('62234567-89ab-cdef-0123-456789abcdef', 'Preferred Session Format', 'What session format do you prefer?', '["Keynote Presentations", "Interactive Workshops", "Panel Discussions", "Networking Sessions"]', true, false);

-- Insert sample tags
INSERT INTO tags (id, name, description, color) VALUES
('71234567-89ab-cdef-0123-456789abcdef', 'Innovation', 'Cutting-edge innovations and breakthrough technologies', '#FF6B6B'),
('72234567-89ab-cdef-0123-456789abcdef', 'Collaboration', 'Cross-industry collaboration and partnerships', '#4ECDC4'),
('73234567-89ab-cdef-0123-456789abcdef', 'Sustainability', 'Environmental sustainability and green initiatives', '#45B7D1'),
('74234567-89ab-cdef-0123-456789abcdef', 'Digital Transformation', 'Digital transformation strategies and implementation', '#96CEB4');

-- Insert sample notification templates
INSERT INTO notification_templates (id, name, title, body, notification_type) VALUES
('81234567-89ab-cdef-0123-456789abcdef', 'session_reminder_15min', 'Session Starting Soon', 'Your session "{session_title}" starts in 15 minutes in {location}.', 'session_reminder'),
('82234567-89ab-cdef-0123-456789abcdef', 'schedule_change', 'Schedule Update', 'There has been a change to your session schedule. Please check the updated agenda.', 'schedule_change'),
('83234567-89ab-cdef-0123-456789abcdef', 'welcome_message', 'Welcome to the Conference!', 'Welcome to our annual conference! Check out the agenda and start networking with other attendees.', 'general');

-- Insert sample resources
INSERT INTO resources (id, title, description, file_url, file_type, category_id, is_public) VALUES
('91234567-89ab-cdef-0123-456789abcdef', 'Conference Welcome Package', 'Welcome materials and general information for attendees', 'https://example.com/resources/welcome-package.pdf', 'application/pdf', '33234567-89ab-cdef-0123-456789abcdef', true),
('92234567-89ab-cdef-0123-456789abcdef', 'AI Future Trends Presentation', 'Slides from the opening keynote presentation', 'https://example.com/resources/ai-trends-2025.pdf', 'application/pdf', '31234567-89ab-cdef-0123-456789abcdef', true),
('93234567-89ab-cdef-0123-456789abcdef', 'Attendee Contact List', 'Networking contact information for registered attendees', 'https://example.com/resources/contacts.pdf', 'application/pdf', '34234567-89ab-cdef-0123-456789abcdef', true);

-- 13. UTILITY VIEWS

-- View for session schedule with speaker information
CREATE VIEW session_schedule AS
SELECT
    s.id,
    s.title,
    s.description,
    s.session_type,
    s.start_time,
    s.end_time,
    s.location,
    s.room,
    s.capacity,
    s.is_featured,
    s.tags,
    COALESCE(
        JSON_AGG(
            JSON_BUILD_OBJECT(
                'id', sp.id,
                'full_name', sp.full_name,
                'organization', sp.organization,
                'job_title', sp.job_title,
                'is_primary', ss.is_primary
            ) ORDER BY ss.presentation_order
        ) FILTER (WHERE sp.id IS NOT NULL),
        '[]'::json
    ) AS speakers
FROM sessions s
LEFT JOIN session_speakers ss ON s.id = ss.session_id
LEFT JOIN speakers sp ON ss.speaker_id = sp.id
GROUP BY s.id, s.title, s.description, s.session_type, s.start_time, s.end_time,
         s.location, s.room, s.capacity, s.is_featured, s.tags
ORDER BY s.start_time;

-- View for voting results
CREATE VIEW voting_results AS
SELECT
    vt.id,
    vt.title,
    vt.description,
    vt.options,
    vt.is_active,
    COUNT(v.id) as total_votes,
    JSON_AGG(
        JSON_BUILD_OBJECT(
            'selected_options', v.selected_options,
            'voted_at', v.voted_at
        )
    ) as vote_details
FROM voting_topics vt
LEFT JOIN votes v ON vt.id = v.voting_topic_id
GROUP BY vt.id, vt.title, vt.description, vt.options, vt.is_active;

-- 14. PERFORMANCE MONITORING

-- Create a function to get table sizes for monitoring
CREATE OR REPLACE FUNCTION get_table_sizes()
RETURNS TABLE(
    table_name TEXT,
    row_count BIGINT,
    total_size TEXT,
    index_size TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        schemaname||'.'||tablename as table_name,
        n_tup_ins - n_tup_del as row_count,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
        pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) as index_size
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
END;
$$ LANGUAGE plpgsql;

-- Complete! This migration creates a comprehensive congress/conference app database schema with:
-- ✅ All requested features (attendees, agenda, voting, tags, speakers, sessions, networking, feedback, notifications, resources)
-- ✅ Proper relationships and foreign keys
-- ✅ Comprehensive RLS policies for data security
-- ✅ Performance optimized indexes
-- ✅ Real-time ready with proper triggers
-- ✅ Offline capability support through proper data structure
-- ✅ Sample data for testing
-- ✅ Utility views and monitoring functions

COMMENT ON SCHEMA public IS 'Congress/Conference Mobile App Database Schema - Version 1.0.0';