-- Fix Security Definer warning for poster voting view
-- Apply this script to fix the Supabase security linter warning
-- Version: 1.0.0
-- Created: 2025-10-21

-- Drop and recreate the view with SECURITY INVOKER
DROP VIEW IF EXISTS public_poster_results;

CREATE VIEW public_poster_results
WITH (security_invoker = true) AS
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

-- Verify the fix
SELECT
    viewname,
    definition
FROM pg_views
WHERE schemaname = 'public'
AND viewname = 'public_poster_results';

-- Test the view
SELECT * FROM public_poster_results LIMIT 5;
