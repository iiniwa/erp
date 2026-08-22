module Api
  module V1
    # t.system settings (spec section 10): a singleton row (SystemSetting.instance
    # always resolves to system_id=1) covering company/bank/tax info plus
    # logo/favicon/seal uploads. Gated to system_admin only (see
    # SystemSettingPolicy) — never through t.role_permissions, since this
    # configures infrastructure the whole app depends on.
    class SystemSettingsController < BaseController
      before_action :authenticate_session!
      before_action :enforce_password_reset!
      before_action :require_normal_session!
      before_action :set_system_setting

      def show
        authorize @system_setting
        render json: { system_setting: serialize(@system_setting) }
      end

      # Uploads happen before the settings row is saved (so validation
      # errors can still be surfaced together with any file problems), but
      # nothing about storage is committed until #save succeeds: the old
      # file is only deleted afterward, and a failed save unwinds the
      # newly uploaded object + StoredFile instead of leaving the setting
      # pointed at a leftover file_id no row ever confirmed.
      def update
        authorize @system_setting

        pending_uploads = stage_uploaded_files
        @system_setting.assign_attributes(system_setting_params)
        @system_setting.updated_by = current_user.user_code

        if @system_setting.save
          pending_uploads.each_value { |upload| retire_old_file(upload[:old_file]) }
          render json: { system_setting: serialize(@system_setting) }
        else
          pending_uploads.each_value { |upload| discard_new_file(upload) }
          render json: { errors: @system_setting.errors.full_messages }, status: :unprocessable_entity
        end
      rescue FileStorageService::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # Streams a logo/favicon/seal's bytes back through the BFF (the
      # actual file lives in SFTPGo, which the frontend can't reach
      # directly — see FileStorageService). Gated the same as #show since
      # this phase has no public-facing branding surface yet.
      def file
        authorize @system_setting, :show?

        association = params[:field].to_sym
        unless SystemSetting::FILE_ASSOCIATIONS.include?(association)
          return render json: { error: "not_found" }, status: :not_found
        end

        stored_file = @system_setting.public_send(association)
        return render json: { error: "not_found" }, status: :not_found unless stored_file

        content = FileStorageService.download(stored_file.file_path)
        send_data content, type: stored_file.content_type, filename: stored_file.file_name, disposition: "inline"
      end

      private

      def set_system_setting
        @system_setting = SystemSetting.instance
      end

      def stage_uploaded_files
        SystemSetting::FILE_ASSOCIATIONS.each_with_object({}) do |association, pending|
          upload = params[association]
          next unless upload

          pending[association] = stage_uploaded_file(association, upload)
        end
      end

      # Uploads to SFTPGo and creates the StoredFile row immediately (so a
      # bad upload is caught before touching @system_setting at all), but
      # only points @system_setting at it in memory — the caller decides
      # whether to keep or discard this once #save has actually run.
      def stage_uploaded_file(association, upload)
        old_file = @system_setting.public_send(association)

        object_key = FileStorageService.upload(
          file_type: "general",
          filename: upload.original_filename,
          io: upload,
          content_type: upload.content_type
        )

        stored_file = StoredFile.create!(
          file_type: :general,
          file_path: object_key,
          file_name: upload.original_filename,
          content_type: upload.content_type,
          file_size: upload.size,
          uploaded_by: current_user.user_code
        )
        @system_setting.public_send("#{association}=", stored_file)

        { stored_file: stored_file, old_file: old_file }
      end

      def retire_old_file(old_file)
        return unless old_file

        FileStorageService.delete(old_file.file_path)
        old_file.soft_delete!
      end

      def discard_new_file(upload)
        FileStorageService.delete(upload[:stored_file].file_path)
        upload[:stored_file].destroy!
      end

      def system_setting_params
        params.permit(
          :system_name, :company_name, :company_post, :company_address, :company_tel, :company_email,
          :company_invoice_number, :company_corporate_number, :representative_position, :representative_name,
          :bank_name, :bank_branch_name, :bank_account_type, :bank_account_number, :bank_account_holder,
          :default_tax_rate, :fiscal_year_end_month, :login_lockout_count
        )
      end

      def serialize(system_setting)
        system_setting.attributes.symbolize_keys.slice(
          :system_name, :company_name, :company_post, :company_address, :company_tel, :company_email,
          :company_invoice_number, :company_corporate_number, :representative_position, :representative_name,
          :bank_name, :bank_branch_name, :bank_account_type, :bank_account_number, :bank_account_holder,
          :default_tax_rate, :fiscal_year_end_month, :login_lockout_count, :updated_at, :updated_by
        ).merge(
          SystemSetting::FILE_ASSOCIATIONS.index_with { |association| serialize_file(system_setting, association) }
        )
      end

      def serialize_file(system_setting, association)
        stored_file = system_setting.public_send(association)
        return nil unless stored_file

        { file_name: stored_file.file_name, url: "/api/v1/system_setting/files/#{association}" }
      end
    end
  end
end
