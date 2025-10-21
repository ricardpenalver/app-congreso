-- Poster Voting System Database Schema
-- Supabase PostgreSQL Migration
-- Version: 1.0.0
-- Created: 2025-10-21

-- ============================================
-- POSTER VOTING SYSTEM TABLES
-- ============================================

-- Posters table
CREATE TABLE posters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    subtitle TEXT,
    author_name TEXT NOT NULL,
    author_organization TEXT,
    thumbnail_url TEXT NOT NULL,
    full_image_url TEXT NOT NULL,
    description TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Poster votes table (each attendee can vote for up to 3 posters)
CREATE TABLE poster_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attendee_id UUID REFERENCES attendees(id) ON DELETE CASCADE,
    poster_id UUID REFERENCES posters(id) ON DELETE CASCADE,
    device_fingerprint TEXT, -- For anonymous voting (fallback)
    voted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Ensure unique vote per attendee per poster
    CONSTRAINT unique_poster_vote UNIQUE (attendee_id, poster_id),
    CONSTRAINT unique_anonymous_poster_vote UNIQUE (device_fingerprint, poster_id)
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX idx_posters_active ON posters(is_active) WHERE is_active = true;
CREATE INDEX idx_posters_display_order ON posters(display_order);
CREATE INDEX idx_poster_votes_poster ON poster_votes(poster_id);
CREATE INDEX idx_poster_votes_attendee ON poster_votes(attendee_id);
CREATE INDEX idx_poster_votes_device ON poster_votes(device_fingerprint);

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER update_posters_updated_at
    BEFORE UPDATE ON posters
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to validate max 3 votes per attendee
CREATE OR REPLACE FUNCTION validate_max_poster_votes()
RETURNS TRIGGER AS $$
DECLARE
    vote_count INTEGER;
BEGIN
    -- Count existing votes for this attendee (including this one)
    IF NEW.attendee_id IS NOT NULL THEN
        SELECT COUNT(*) INTO vote_count
        FROM poster_votes
        WHERE attendee_id = NEW.attendee_id;

        IF vote_count >= 3 THEN
            RAISE EXCEPTION 'Maximum 3 votes per attendee reached';
        END IF;
    END IF;

    -- Count existing votes for this device (anonymous voting)
    IF NEW.device_fingerprint IS NOT NULL AND NEW.attendee_id IS NULL THEN
        SELECT COUNT(*) INTO vote_count
        FROM poster_votes
        WHERE device_fingerprint = NEW.device_fingerprint
        AND attendee_id IS NULL;

        IF vote_count >= 3 THEN
            RAISE EXCEPTION 'Maximum 3 votes per device reached';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER validate_max_poster_votes_trigger
    BEFORE INSERT ON poster_votes
    FOR EACH ROW
    EXECUTE FUNCTION validate_max_poster_votes();

-- ============================================
-- VIEWS FOR RESULTS
-- ============================================

-- Public voting results view
CREATE OR REPLACE VIEW public_poster_results AS
SELECT
    p.id,
    p.title,
    p.subtitle,
    p.author_name,
    p.author_organization,
    p.thumbnail_url,
    p.display_order,
    COUNT(pv.id)::INTEGER as total_votes
FROM posters p
LEFT JOIN poster_votes pv ON p.id = pv.poster_id
WHERE p.is_active = true
GROUP BY p.id, p.title, p.subtitle, p.author_name, p.author_organization, p.thumbnail_url, p.display_order
ORDER BY total_votes DESC, p.display_order ASC;

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on tables
ALTER TABLE posters ENABLE ROW LEVEL SECURITY;
ALTER TABLE poster_votes ENABLE ROW LEVEL SECURITY;

-- Posters policies (read-only for everyone)
CREATE POLICY "Anyone can view active posters"
    ON posters FOR SELECT
    USING (is_active = true);

CREATE POLICY "Only admins can insert posters"
    ON posters FOR INSERT
    WITH CHECK (false); -- Will be enabled later for admin users

CREATE POLICY "Only admins can update posters"
    ON posters FOR UPDATE
    USING (false); -- Will be enabled later for admin users

CREATE POLICY "Only admins can delete posters"
    ON posters FOR DELETE
    USING (false); -- Will be enabled later for admin users

-- Poster votes policies
CREATE POLICY "Anyone can insert poster votes"
    ON poster_votes FOR INSERT
    WITH CHECK (true); -- Trigger handles vote limit validation

CREATE POLICY "Anyone can view poster votes"
    ON poster_votes FOR SELECT
    USING (true);

CREATE POLICY "Users can delete their own votes"
    ON poster_votes FOR DELETE
    USING (
        attendee_id = auth.uid() OR
        device_fingerprint IS NOT NULL -- Allow anonymous deletion
    );

-- ============================================
-- SAMPLE DATA (PLACEHOLDER - TO BE UPDATED)
-- ============================================

-- Insert sample posters (will be replaced with real data)
INSERT INTO posters (title, subtitle, author_name, author_organization, thumbnail_url, full_image_url, description, display_order) VALUES
('Poster 1', 'Subtítulo del Poster 1', 'Autor 1', 'Universidad Example 1', 'https://via.placeholder.com/300x400?text=Poster+1', 'https://via.placeholder.com/800x1200?text=Poster+1', 'Descripción detallada del poster 1', 1),
('Poster 2', 'Subtítulo del Poster 2', 'Autor 2', 'Universidad Example 2', 'https://via.placeholder.com/300x400?text=Poster+2', 'https://via.placeholder.com/800x1200?text=Poster+2', 'Descripción detallada del poster 2', 2),
('Poster 3', 'Subtítulo del Poster 3', 'Autor 3', 'Universidad Example 3', 'https://via.placeholder.com/300x400?text=Poster+3', 'https://via.placeholder.com/800x1200?text=Poster+3', 'Descripción detallada del poster 3', 3),
('Poster 4', 'Subtítulo del Poster 4', 'Autor 4', 'Universidad Example 4', 'https://via.placeholder.com/300x400?text=Poster+4', 'https://via.placeholder.com/800x1200?text=Poster+4', 'Descripción detallada del poster 4', 4),
('Poster 5', 'Subtítulo del Poster 5', 'Autor 5', 'Universidad Example 5', 'https://via.placeholder.com/300x400?text=Poster+5', 'https://via.placeholder.com/800x1200?text=Poster+5', 'Descripción detallada del poster 5', 5);

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Verify RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('posters', 'poster_votes');

-- Verify policies exist
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('posters', 'poster_votes')
ORDER BY tablename, policyname;

-- Check vote counts
SELECT * FROM public_poster_results;
