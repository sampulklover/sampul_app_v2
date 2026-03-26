-- Standardise hibah status handling to align with other modules

ALTER TABLE public.hibah
ADD COLUMN IF NOT EXISTS status text
    DEFAULT 'submitted'
    CHECK (status IN ('draft', 'pending_review', 'under_review', 'approved', 'rejected'));

-- Backfill from existing submission_status where available
UPDATE public.hibah
SET status = submission_status
WHERE status IS NULL
  AND submission_status IS NOT NULL;

