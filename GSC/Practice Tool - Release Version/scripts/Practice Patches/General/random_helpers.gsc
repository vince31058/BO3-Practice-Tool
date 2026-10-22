// Shared helpers for patches that set up a gum cycle.

// The game's array::randomize swaps every slot with a random slot, which doesn't give every
// order the same chance. This is a proper Fisher-Yates shuffle (every order equally likely).
ShuffleArray(arr)
{
    for(i = arr.size - 1; i > 0; i--)
    {
        j = RandomInt(i + 1);
        temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
    return arr;
}

// Patches pick their gum cycle at the same moment of every load, so the game's random numbers
// can come out the same each time. Skip ahead a number of random rolls based on the real
// clock first, so the order really changes from game to game.
MixRandom()
{
    n = GetUTC() % 200;
    for(i = 0; i < n; i++) RandomInt(100);
}
