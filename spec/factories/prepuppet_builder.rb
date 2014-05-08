FactoryGirl.define do
  factory :prepuppet_builder, :class => Bebox::PrepuppetBuilder do
  	stages ['vagrant', 'production']
  	builder FactoryGirl.build(:builder)
    initialize_with { new(builder, stages) }
  end
end