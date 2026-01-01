# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'A2UI Union Types' do
  describe A2UI::Value do
    it 'accepts LiteralValue' do
      value = A2UI::LiteralValue.new(value: 'Hello World')
      expect(value.value).to eq('Hello World')
    end

    it 'accepts PathReference' do
      value = A2UI::PathReference.new(path: '/user/name')
      expect(value.path).to eq('/user/name')
    end
  end

  describe A2UI::Children do
    it 'accepts ExplicitChildren' do
      children = A2UI::ExplicitChildren.new(ids: ['child1', 'child2', 'child3'])
      expect(children.ids).to eq(['child1', 'child2', 'child3'])
    end

    it 'accepts DataDrivenChildren' do
      children = A2UI::DataDrivenChildren.new(
        path: '/items',
        template_id: 'item-template'
      )
      expect(children.path).to eq('/items')
      expect(children.template_id).to eq('item-template')
    end
  end

  describe A2UI::DataValue do
    it 'accepts StringValue' do
      value = A2UI::StringValue.new(key: 'name', string: 'Alice')
      expect(value.key).to eq('name')
      expect(value.string).to eq('Alice')
    end

    it 'accepts NumberValue' do
      value = A2UI::NumberValue.new(key: 'count', number: 42.0)
      expect(value.key).to eq('count')
      expect(value.number).to eq(42.0)
    end

    it 'accepts BooleanValue' do
      value = A2UI::BooleanValue.new(key: 'active', boolean: true)
      expect(value.key).to eq('active')
      expect(value.boolean).to be true
    end

    it 'accepts ObjectValue with nested entries' do
      value = A2UI::ObjectValue.new(
        key: 'config',
        entries: { 'theme' => 'dark', 'enabled' => true }
      )

      expect(value.key).to eq('config')
      expect(value.entries.size).to eq(2)
      expect(value.entries['theme']).to eq('dark')
      expect(value.entries['enabled']).to be true
    end
  end

  describe A2UI::Component do
    it 'creates TextComponent with LiteralValue' do
      component = A2UI::TextComponent.new(
        id: 'title',
        content: A2UI::LiteralValue.new(value: 'Welcome'),
        usage_hint: A2UI::TextUsageHint::H1
      )

      expect(component.id).to eq('title')
      expect(component.content).to be_a(A2UI::LiteralValue)
      expect(component.usage_hint).to eq(A2UI::TextUsageHint::H1)
    end

    it 'creates TextComponent with PathReference' do
      component = A2UI::TextComponent.new(
        id: 'user-name',
        content: A2UI::PathReference.new(path: '/user/name')
      )

      expect(component.content).to be_a(A2UI::PathReference)
      expect(component.content.path).to eq('/user/name')
    end

    it 'creates ButtonComponent with Action' do
      component = A2UI::ButtonComponent.new(
        id: 'submit-btn',
        label: A2UI::LiteralValue.new(value: 'Submit'),
        action: A2UI::Action.new(
          name: 'submit_form',
          context: [
            A2UI::ContextBinding.new(key: 'form_data', path: '/form')
          ]
        )
      )

      expect(component.action.name).to eq('submit_form')
      expect(component.action.context.size).to eq(1)
      expect(component.action.context.first.key).to eq('form_data')
    end

    it 'creates TextFieldComponent bound to data path' do
      component = A2UI::TextFieldComponent.new(
        id: 'email-field',
        value: A2UI::PathReference.new(path: '/user/email'),
        input_type: A2UI::InputType::Email,
        label: 'Email Address',
        is_required: true
      )

      expect(component.value.path).to eq('/user/email')
      expect(component.input_type).to eq(A2UI::InputType::Email)
      expect(component.is_required).to be true
    end

    it 'creates RowComponent with ExplicitChildren' do
      component = A2UI::RowComponent.new(
        id: 'button-row',
        children: A2UI::ExplicitChildren.new(ids: ['cancel-btn', 'submit-btn']),
        distribution: A2UI::Distribution::SpaceBetween,
        gap: 16
      )

      expect(component.children).to be_a(A2UI::ExplicitChildren)
      expect(component.children.ids).to eq(['cancel-btn', 'submit-btn'])
      expect(component.distribution).to eq(A2UI::Distribution::SpaceBetween)
    end

    it 'creates ListComponent with DataDrivenChildren' do
      component = A2UI::ListComponent.new(
        id: 'todo-list',
        children: A2UI::DataDrivenChildren.new(
          path: '/todos',
          template_id: 'todo-item'
        )
      )

      expect(component.children).to be_a(A2UI::DataDrivenChildren)
      expect(component.children.path).to eq('/todos')
    end

    it 'creates TabsComponent with TabItems' do
      component = A2UI::TabsComponent.new(
        id: 'settings-tabs',
        tabs: [
          A2UI::TabItem.new(label: 'General', child_id: 'general-panel'),
          A2UI::TabItem.new(label: 'Privacy', child_id: 'privacy-panel'),
          A2UI::TabItem.new(label: 'Advanced', child_id: 'advanced-panel')
        ],
        active_index: 1
      )

      expect(component.id).to eq('settings-tabs')
      expect(component.tabs.size).to eq(3)
      expect(component.tabs.first.label).to eq('General')
      expect(component.tabs.first.child_id).to eq('general-panel')
      expect(component.active_index).to eq(1)
    end

    it 'creates ModalComponent with defaults' do
      component = A2UI::ModalComponent.new(
        id: 'confirm-modal',
        child_id: 'confirm-content',
        title: 'Confirm Action'
      )

      expect(component.id).to eq('confirm-modal')
      expect(component.child_id).to eq('confirm-content')
      expect(component.title).to eq('Confirm Action')
      expect(component.is_open).to be false
      expect(component.size).to eq(A2UI::ModalSize::Medium)
      expect(component.dismissible).to be true
    end

    it 'creates ModalComponent with custom size and open state' do
      component = A2UI::ModalComponent.new(
        id: 'fullscreen-modal',
        child_id: 'video-player',
        is_open: true,
        size: A2UI::ModalSize::FullScreen,
        dismissible: false
      )

      expect(component.is_open).to be true
      expect(component.size).to eq(A2UI::ModalSize::FullScreen)
      expect(component.dismissible).to be false
    end
  end

  describe 'enum serialization' do
    it 'serializes TextUsageHint' do
      expect(A2UI::TextUsageHint::H1.serialize).to eq('h1')
      expect(A2UI::TextUsageHint::Body.serialize).to eq('body')
    end

    it 'serializes StreamAction' do
      expect(A2UI::StreamAction::Append.serialize).to eq('append')
      expect(A2UI::StreamAction::Replace.serialize).to eq('replace')
    end

    it 'serializes ActionResponseType' do
      expect(A2UI::ActionResponseType::UpdateUI.serialize).to eq('update_ui')
      expect(A2UI::ActionResponseType::Navigate.serialize).to eq('navigate')
    end

    it 'serializes ModalSize' do
      expect(A2UI::ModalSize::Small.serialize).to eq('small')
      expect(A2UI::ModalSize::Medium.serialize).to eq('medium')
      expect(A2UI::ModalSize::Large.serialize).to eq('large')
      expect(A2UI::ModalSize::FullScreen.serialize).to eq('fullscreen')
    end

    it 'serializes UIDecisionType' do
      expect(A2UI::UIDecisionType::ComponentChoice.serialize).to eq('component_choice')
      expect(A2UI::UIDecisionType::LayoutStructure.serialize).to eq('layout_structure')
      expect(A2UI::UIDecisionType::DataBinding.serialize).to eq('data_binding')
      expect(A2UI::UIDecisionType::Styling.serialize).to eq('styling')
      expect(A2UI::UIDecisionType::Interaction.serialize).to eq('interaction')
    end
  end

  describe A2UI::UIDecisionEvidence do
    it 'captures component choice reasoning' do
      evidence = A2UI::UIDecisionEvidence.new(
        decision_type: A2UI::UIDecisionType::ComponentChoice,
        component_id: 'booking-card',
        choice: 'Card',
        rationale: 'Card provides visual grouping for related booking information with elevation.',
        alternatives_considered: ['Column', 'Row with border']
      )

      expect(evidence.decision_type).to eq(A2UI::UIDecisionType::ComponentChoice)
      expect(evidence.component_id).to eq('booking-card')
      expect(evidence.choice).to eq('Card')
      expect(evidence.rationale).to include('visual grouping')
      expect(evidence.alternatives_considered).to include('Column')
    end

    it 'captures layout structure reasoning' do
      evidence = A2UI::UIDecisionEvidence.new(
        decision_type: A2UI::UIDecisionType::LayoutStructure,
        choice: 'Column with SpaceBetween distribution',
        rationale: 'Vertical layout for sequential form fields with consistent spacing.'
      )

      expect(evidence.decision_type).to eq(A2UI::UIDecisionType::LayoutStructure)
      expect(evidence.component_id).to be_nil
      expect(evidence.alternatives_considered).to eq([])
    end

    it 'captures data binding reasoning' do
      evidence = A2UI::UIDecisionEvidence.new(
        decision_type: A2UI::UIDecisionType::DataBinding,
        component_id: 'user-name-field',
        choice: 'PathReference to /user/name',
        rationale: 'Bound to user data for personalization and form pre-fill.'
      )

      expect(evidence.decision_type).to eq(A2UI::UIDecisionType::DataBinding)
      expect(evidence.choice).to include('/user/name')
    end
  end
end
