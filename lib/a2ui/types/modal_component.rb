# typed: strict
# frozen_string_literal: true

module A2UI
  class ModalComponent < T::Struct
    const :id, String
    const :child_id, String, description: 'ID of the content component inside the modal'
    const :title, String, default: '', description: 'Optional modal title'
    const :is_open, T::Boolean, default: false, description: 'Whether the modal is currently visible'
    const :size, ModalSize, default: ModalSize::Medium, description: 'Modal size variant'
    const :dismissible, T::Boolean, default: true, description: 'Whether the modal can be dismissed by clicking outside'
  end
end
