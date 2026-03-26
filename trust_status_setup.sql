-- Standardise trust status handling to align with other modules

ALTER TABLE public.trust
ADD COLUMN IF NOT EXISTS status text
    DEFAULT 'submitted'
    CHECK (status IN ('draft', 'submitted', 'approved', 'rejected'));

-- Backfill from existing doc_status where available
UPDATE public.trust
SET status = doc_status
WHERE status IS NULL
  AND doc_status IS NOT NULL;

