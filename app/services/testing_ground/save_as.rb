# Given a testing ground, creates a duplicate -- along with all associated
# records -- with a new name.
class TestingGround::SaveAs
  # Assocations which must also be duplicated.
  ASSOCIATIONS = %i( business_case gas_asset_list selected_strategy )

  def self.run(*args)
    new(*args).run
  end

  def initialize(original, name, user = nil)
    @original = original
    @name     = name
    @user     = user || original.user
  end

  def run
    duplicate = @original.dup

    TestingGround.transaction do
      duplicate.name = @name
      duplicate.user = @user

      duplicate.save!

      duplicate_associations!(duplicate)
    end

    duplicate
  end

  private

  def duplicate_associations!(duplicate)
    ASSOCIATIONS.each do |name|
      if association = @original.public_send(name)
        duplicate_assoc = association.dup
        duplicate_assoc.testing_ground = duplicate

        duplicate_assoc.save!
      end
    end
  end
end
