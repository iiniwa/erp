"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";
import Button from "@/components/ui/Button";
import Modal from "@/components/ui/Modal";
import { useToast } from "@/components/ui/ToastProvider";

export default function EmployeeActions({
  userCode,
  isRetired,
}: {
  userCode: string;
  isRetired: boolean;
}) {
  const router = useRouter();
  const { showToast } = useToast();
  const [confirmingRetire, setConfirmingRetire] = useState(false);
  const [confirmingDelete, setConfirmingDelete] = useState(false);

  // Stable identities so Modal's focus-trap effect doesn't re-fire on
  // unrelated re-renders (see Header.tsx for the same fix).
  const closeRetireModal = useCallback(() => setConfirmingRetire(false), []);
  const closeDeleteModal = useCallback(() => setConfirmingDelete(false), []);

  async function handleRetire() {
    try {
      const response = await fetch(`/api/employees/${userCode}/retire`, { method: "POST" });
      if (!response.ok) {
        showToast("退職処理に失敗しました。", "error");
        return;
      }
      showToast("退職処理を行いました。");
      router.refresh();
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    } finally {
      setConfirmingRetire(false);
    }
  }

  async function handleDelete() {
    try {
      const response = await fetch(`/api/employees/${userCode}`, { method: "DELETE" });
      if (!response.ok) {
        showToast("削除に失敗しました。", "error");
        return;
      }
      showToast("削除しました。");
      router.push("/employees");
      router.refresh();
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    } finally {
      setConfirmingDelete(false);
    }
  }

  return (
    <div className="flex gap-3">
      {!isRetired && (
        <Button type="button" variant="secondary" onClick={() => setConfirmingRetire(true)}>
          退職処理
        </Button>
      )}
      <Button type="button" variant="danger" onClick={() => setConfirmingDelete(true)}>
        削除
      </Button>

      <Modal
        open={confirmingRetire}
        title="退職処理の確認"
        onConfirm={handleRetire}
        onCancel={closeRetireModal}
        confirmLabel="退職処理を行う"
      >
        この従業員を退職済みに設定します。よろしいですか？
      </Modal>

      <Modal
        open={confirmingDelete}
        title="削除の確認"
        onConfirm={handleDelete}
        onCancel={closeDeleteModal}
        confirmLabel="削除する"
        confirmVariant="danger"
      >
        この従業員情報を削除します。よろしいですか？（一覧から見えなくなります）
      </Modal>
    </div>
  );
}
