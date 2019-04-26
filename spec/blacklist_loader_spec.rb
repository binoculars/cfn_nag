require 'spec_helper'
require 'cfn-nag/blacklist_loader'
require 'cfn-nag/rule_id_set'
require 'cfn-nag/rule_registry'
require 'cfn-nag/violation'
require 'set'

describe BlackListLoader do
  describe '#load' do
    before(:all) do
      @rule_registry = RuleRegistry.new

      @rule_registry.definition(id: 'id1',
                                type: Violation::WARNING,
                                message: 'fakeo')
      @rule_registry.definition(id: 'id2',
                                type: Violation::WARNING,
                                message: 'fakeo2')
    end

    context 'empty blacklist' do
      it 'should raise an error' do
        expect do
          BlackListLoader.new(nil).load blacklist_definition: ''
        end.to raise_error 'Empty profile'
      end
    end

    context 'malformed yaml blacklist' do
      it 'should raise an error' do
        expect do
          BlackListLoader.new(nil).load blacklist_definition: 'garbage'
        end.to raise_error 'Blacklist is malformed'
      end
    end

    context 'yaml missing RulesToSuppress' do
      it 'should raise an error' do
        expect do
          BlackListLoader.new(nil).load blacklist_definition: 'Foo: moo'
        end.to raise_error 'Missing RulesToSuppress key in black list'
      end
    end

    context 'happy path' do
      it 'should return a profile object' do
        blacklist_definition = <<END
RulesToSuppress:
  - id: id1
    reason: i dont wanna
  - id: id2
    reason: really dont wanna
END
        rule_id_set = BlackListLoader.new(@rule_registry).load blacklist_definition: blacklist_definition
        expect(rule_id_set.rule_ids).to eq Set.new %w[id1 id2]
      end
    end

    context 'non-existent rule number' do
      it 'should raise an error' do
        blacklist_definition = <<END
RulesToSuppress:
  - id: FAKEID1
    reason: i dont wanna
END

        expect do
          BlackListLoader.new(@rule_registry).load blacklist_definition: blacklist_definition
        end.to raise_error # 'FAKEID is not a legal rule identifier'
      end
    end

  end
end