-- ============================================================
-- tinnitus_intake テーブル作成 + 権限 + 自動削除
-- ent-intake プロジェクト / Supabase SQL Editor で実行
-- (dizziness_intake / hearing_intake と同構造)
-- ============================================================

-- 1) テーブル作成
CREATE TABLE tinnitus_intake (
    id          BIGSERIAL PRIMARY KEY,
    patient_no  SMALLINT NOT NULL CHECK (patient_no BETWEEN 1 AND 999),
    answers     JSONB NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at  TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours')
);

CREATE INDEX idx_tinnitus_expires    ON tinnitus_intake(expires_at);
CREATE INDEX idx_tinnitus_patient_no ON tinnitus_intake(patient_no);

-- 2) RLS 有効化
ALTER TABLE tinnitus_intake ENABLE ROW LEVEL SECURITY;

-- 3) RLS ポリシー
--    anon(患者用) は INSERT のみ可
--    authenticated(医師用) は SELECT 可
CREATE POLICY "anon_can_insert" ON tinnitus_intake
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "authenticated_can_select" ON tinnitus_intake
  FOR SELECT TO authenticated USING (true);

-- 4) GRANT(RLS とは別レイヤーの権限。両方必要)
GRANT INSERT ON tinnitus_intake TO anon;
GRANT USAGE, SELECT ON SEQUENCE tinnitus_intake_id_seq TO anon;
GRANT SELECT ON tinnitus_intake TO authenticated;

-- 5) 24時間経過レコードを毎時0分に削除
SELECT cron.schedule(
    'delete_expired_tinnitus',
    '0 * * * *',
    $$DELETE FROM tinnitus_intake WHERE expires_at < NOW()$$
);

-- ============================================================
-- 採番関数 issue_patient_number() は既存のものをそのまま流用。
-- 全症状で番号空間を共有する設計のため、追加SQL不要。
-- ============================================================
