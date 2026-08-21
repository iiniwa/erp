"use client";

import { useCallback, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import Button from "@/components/ui/Button";
import Modal from "@/components/ui/Modal";
import { useToast } from "@/components/ui/ToastProvider";

export default function AddressActions({ addressId }: { addressId: string }) {
  const router = useRouter();
  const { showToast } = useToast();
  const [confirmingDelete, setConfirmingDelete] = useState(false);
  // Guards against a rapid double-click on the modal's confirm button
  // sending the same destructive request twice (same pattern as
  // EmployeeActions).
  const mutationInFlight = useRef(false);

  const closeDeleteModal = useCallback(() => setConfirmingDelete(false), []);

  async function handleDelete() {
    if (mutationInFlight.current) return;
    mutationInFlight.current = true;

    try {
      const response = await fetch(`/api/addresses/${encodeURIComponent(addressId)}`, {
        method: "DELETE",
      });
      if (!response.ok) {
        showToast("削除に失敗しました。", "error");
        return;
      }
      showToast("削除しました。");
      router.push("/addresses");
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
      <Button type="button" variant="danger" onClick={() => setConfirmingDelete(true)}>
        削除
      </Button>

      <Modal
        open={confirmingDelete}
        title="削除の確認"
        onConfirm={handleDelete}
        onCancel={closeDeleteModal}
        confirmLabel="削除する"
        confirmVariant="danger"
      >
        このアドレス帳情報を削除します。よろしいですか？（一覧から見えなくなります）
      </Modal>
    </div>
  );
}
