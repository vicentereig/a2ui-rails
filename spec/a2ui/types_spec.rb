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
  end
end
