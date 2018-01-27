RSpec.describe(Dry::Monads::Do) do
  include Dry::Monads
  include Dry::Monads::Try::Mixin

  let(:klass) do
    Class.new do
      include Dry::Monads::Do.for(:call)
      include Dry::Monads
      include Dry::Monads::Try::Mixin
    end
  end

  let(:instance) { klass.new }

  context 'with Result' do
    context 'successful case' do
      before do
        klass.class_eval do
          def call
            m1 = Success(1)
            m2 = Success(2)

            one = yield m1
            two = yield m2

            Success(one + two)
          end
        end
      end

      it 'returns the result of a statement' do
        expect(instance.call).to eql(Success(3))
      end
    end

    context 'first failure' do
      before do
        klass.class_eval do
          def call
            m1 = Failure(:no_one)
            m2 = Success(2)

            one = yield m1
            two = yield m2

            Success(one + two)
          end
        end
      end

      it 'returns failure' do
        expect(instance.call).to eql(Failure(:no_one))
      end
    end

    context 'second failure' do
      before do
        klass.class_eval do
          def call
            m1 = Success(1)
            m2 = Failure(:no_two)

            one = yield m1
            two = yield m2

            Success(one + two)
          end
        end
      end

      it 'returns failure' do
        expect(instance.call).to eql(Failure(:no_two))
      end
    end

    context 'with stateful blocks' do
      before do
        klass.class_eval do
          attr_reader :rolled_back

          def initialize
            @rolled_back = false
          end

          def call
            m1 = Success(1)
            m2 = Failure(:no_two)

            transaction do
              one = yield m1
              two = yield m2

              Success(one + two)
            end
          end

          def transaction
            yield
          rescue => e
            @rolled_back = true
            raise e
          end
        end
      end

      it 'halts the executing with an exception' do
        expect(instance.call).to eql(Failure(:no_two))
        expect(instance.rolled_back).to be(true)
      end
    end
  end

  context 'with Maybe' do
    context 'successful case' do
      before do
        klass.class_eval do
          def call
            m1 = Some(1)
            m2 = Some(2)

            Some(yield(m1, m2).reduce(:+))
          end
        end
      end

      it 'returns the result of a statement' do
        expect(instance.call).to eql(Some(3))
      end
    end

    context 'first failure' do
      before do
        klass.class_eval do
          def call
            m1 = None()
            m2 = Some(2)

            Some(yield(m1, m2).reduce(:+))
          end
        end
      end

      it 'returns none' do
        expect(instance.call).to be_none
      end
    end

    context 'second failure' do
      before do
        klass.class_eval do
          def call
            m1 = Some(1)
            m2 = None()

            Some(yield(m1, m2).reduce(:+))
          end
        end
      end

      it 'returns none' do
        expect(instance.call).to be_none
      end
    end
  end

  context 'with Try' do
    context 'successful case' do
      before do
        klass.class_eval do
          def call
            m1 = Try { 1 }
            m2 = Try { 2 }

            Dry::Monads::Try::pure(yield(m1, m2).reduce(:+))
          end
        end
      end

      it 'returns the result of a statement' do
        expect(instance.call).to eql(Dry::Monads::Try::pure(3))
      end
    end

    context 'first failure' do
      before do
        klass.class_eval do
          def call
            m1 = Try { 1 / 0 }
            m2 = Try { 2 }

            Dry::Monads::Try::pure(yield(m1, m2).reduce(:+))
          end
        end
      end

      it 'returns Error' do
        expect(instance.call).to be_error
      end
    end

    context 'second failure' do
      before do
        klass.class_eval do
          def call
            m1 = Try { 1 }
            m2 = Try { 2 / 0 }

            Dry::Monads::Try::pure(yield(m1, m2).reduce(:+))
          end
        end
      end

      it 'returns Error' do
        expect(instance.call).to be_error
      end
    end
  end
end