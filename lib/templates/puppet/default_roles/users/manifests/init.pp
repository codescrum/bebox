# The role class can include many profiles
# Example:
# class roles::example_role {
#   include profiles::category::example_profile_1
#   include profiles::category::example_profile_2
#   ...
#   include profiles::category::example_profile_N
# }
# The profiles can be added/removed to the role manually or through the
# 'bebox role add_profile' and 'bebox role remove_profile' commands.

class roles::users {
  include profiles::base::users::users
  include profiles::base::users::ssh
}