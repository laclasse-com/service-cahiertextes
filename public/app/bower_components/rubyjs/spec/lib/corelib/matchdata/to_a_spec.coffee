describe "MatchData#to_a", ->
  it "returns an array of matches", ->
    expect( R(/(.)(.)(\d+)(\d)/).match("THX1138.").to_a().equals(["HX1138", "H", "X", "113", "8"]) ).toEqual(true)
