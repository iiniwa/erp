"use client";

import { useCallback, useRef, useState } from "react";
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
  // Guards against a rapid double-click on the modal's confirm button
  // sending the same destructive request twice.
  const mutationInFlight = useRef(false);

  // Stable identities so Modal's focus-trap effect doesn't re-fire on
  // unrelated re-renders (see Header.tsx for the same fix).
  const closeRetireModal = useCallback(() => setConfirmingRetire(false), []);
  const closeDeleteModal = useCallback(() => setConfirmingDelete(false), []);

  async function handleRetire() {
    if (mutationInFlight.current) return;
    mutationInFlight.current = true;

    try {
      const encodedUserCode = encodeURIComponent(userCode);
      const response = await fetch(`/api/employees/${encodedUserCode}/retire`, {
        method: "POST",
      });
      if (!response.ok) {
        showToast("退職処理に失敗しました。", "error");
        return;
      }
      showToast("退職処理を行いました。");
      router.refresh();
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    } finally {
      mutationInFlight.current = false;
      setConfirmingRetire(false);
    }
  }

  async function handleDelete() {
    if (mutationInFlight.current) return;
    mutationInFlight.current = true;

    try {
      const response = await fetch(`/api/employees/${encodeURIComponent(userCode)}`, {
        method: "DELETE",
      });
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
      mutationInFlight.current = false;
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
