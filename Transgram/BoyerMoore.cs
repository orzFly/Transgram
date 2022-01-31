public class BoyerMoore
{
    private int[] jmp;
    private byte[] pattern;
    private int len;

    public BoyerMoore(byte[] pattern)
    {
        this.pattern = pattern;
        jmp = new int[256];
        len = this.pattern.Length;
        Array.Fill(jmp, len);
        for (var i = 0; i < len - 1; i++)
        {
            jmp[this.pattern[i]] = len - i - 1;
        }
    }
    
    public int Search(byte[] haystack, int startIndex = 0)
    {
        if (len > haystack.Length) return -1;

        var index = startIndex;
        var limit = haystack.Length - len;
        var lenMinus1 = len - 1;
        while (index <= limit)
        {
            var j = lenMinus1;
            while (j >= 0 && pattern[j] == haystack[index + j])
                j--;
            if (j < 0)
                return index;
            index += jmp[haystack[index + lenMinus1]];
        }
        return -1;
    }
    
    public int[] SearchAll(byte[] haystack, int startIndex = 0)
    {
        if (len > haystack.Length) return new int[] { };

        var index = startIndex;
        var limit = haystack.Length - len;
        var lenMinus1 = len - 1;
        var list = new LinkedList<int>();
        while (index <= limit)
        {
            var j = lenMinus1;
            while (j >= 0 && pattern[j] == haystack[index + j])
                j--;
            if (j < 0)
                list.AddLast(index);
            index += jmp[haystack[index + lenMinus1]];
        }
        return list.ToArray();
    }
}