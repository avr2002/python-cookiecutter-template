"""Tests for `example_pkg.states_info`."""


import pytest
from example_pkg.states_info import (
    is_city_capital_of_state,
    slow_add,
)


# multiple tests in one
@pytest.mark.parametrize(
    argnames="city_name, state, is_capital",
    argvalues=[
        ("Ranchi", "Jharkhand", True),
        ("Patna", "Bihar", True),
        ("Bangalore", "Karnataka", True),
        ("Mumbai", "Maharashtra", True),
        ("Patna", "Jharkhand", False),
    ],
)
def test__is_city_capital_of_state(city_name: str, state: str, is_capital: bool):
    """Assert `is_city_capital_of_state()` return correct answer for given city and state pairs."""
    assert is_city_capital_of_state(city_name=city_name, state=state) == is_capital


@pytest.mark.slow
def test__slow_add():
    """Test `slow_add()`."""
    assert slow_add(1, 2) == 3
