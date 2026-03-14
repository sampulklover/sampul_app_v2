-- Add physical_legal_classification column so we can store
-- whether a physical asset is movable or immovable, without
-- stuffing that information into the remarks field.
-- Run this migration in your Supabase SQL editor.

ALTER TABLE public.digital_assets
ADD COLUMN IF NOT EXISTS physical_legal_classification text CHECK (physical_legal_classification IN ('movable', 'immovable'));

COMMENT ON COLUMN public.digital_assets.physical_legal_classification IS
'For physical assets only: legal classification (movable or immovable).';

