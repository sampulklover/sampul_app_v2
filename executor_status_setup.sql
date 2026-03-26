-- Standardise executor status handling similar to inform_death/trust

ALTER TABLE public.executor
ADD COLUMN IF NOT EXISTS status text
    DEFAULT 'submitted'
    CHECK (status IN ('draft', 'submitted', 'under_review', 'approved', 'rejected'));

