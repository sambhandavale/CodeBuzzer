class DsaQuotes {
  static const List<String> quotes = [
    // 1) Introduction & Asymptotic Notations
    "Big O notation describes the worst-case scenario. Always prepare for the worst!",
    "Omega (Ω) notation gives the best-case time complexity. Theta (Θ) gives the exact bound.",
    "Space complexity includes both auxiliary space and the space used by input values.",
    "Nested loops don't always mean O(N²). Analyze how the inner loop variable changes!",
    "Recursion tree method is a visual way to solve recurrence relations.",
    "Dropping constants in Big O is crucial because we care about the growth rate, not exact operations.",

    // 2) Mathematics
    "The GCD of two numbers can be found in O(log(min(a,b))) using the Euclidean algorithm.",
    "LCM(a, b) = (a * b) / GCD(a, b). Be careful of integer overflow when multiplying a and b!",
    "Sieve of Eratosthenes can find all primes up to N in O(N log(log N)) time.",
    "A number is prime if it has no divisors up to its square root.",
    "Computing power x^n can be done in O(log n) time using Binary Exponentiation.",

    // 3) Bit Magic
    "To check if the K-th bit is set: (N & (1 << K)) != 0.",
    "XOR of a number with itself is 0. XOR with 0 is the number itself.",
    "Brian Kernighan’s algorithm counts set bits in O(set bits) by repeatedly doing N = N & (N - 1).",
    "If N is a power of 2, it has exactly one set bit. Check it with (N & (N - 1)) == 0.",
    "A left shift by 1 is equivalent to multiplying by 2. Right shift is dividing by 2.",

    // 4) Recursion
    "Every recursive function must have a base case to avoid stack overflow.",
    "Tail recursion is when the recursive call is the last operation in the function. It can be optimized by compilers.",
    "The Tower of Hanoi with N disks takes exactly 2^N - 1 moves.",
    "Recursion uses an implicit call stack, which counts towards auxiliary space complexity.",
    "Josephus problem can be solved recursively using the formula: J(n, k) = (J(n-1, k) + k) % n.",

    // 5) Arrays
    "Prefix Sum arrays allow O(1) range sum queries after an O(N) preprocessing step.",
    "Sliding Window is perfect for finding the maximum or minimum in contiguous subarrays.",
    "Kadane's Algorithm finds the maximum subarray sum in O(N) time and O(1) space.",
    "The Moore's Voting Algorithm finds the majority element (appears > N/2 times) in O(N) time.",
    "To rotate an array by D elements in O(N) time, reverse the first D, then the rest, then the whole array.",

    // 6) Searching
    "Binary Search requires a sorted array and runs in O(log N) time.",
    "Binary Search isn't just for arrays! It can be used on any monotonic function (Binary Search on Answer).",
    "The Two Pointer approach is excellent for finding pairs in a sorted array that sum to X.",
    "To find the peak element in a mountain array, use Binary Search to find the inflection point.",
    "When doing Binary Search, use mid = low + (high - low) / 2 to prevent integer overflow.",

    // 7) Sorting
    "Merge Sort is a stable, divide-and-conquer algorithm with a guaranteed O(N log N) time.",
    "Quick Sort has a worst-case of O(N²), but its average case O(N log N) is highly cache-friendly.",
    "Counting Sort is O(N + K) but only works well when the range of elements (K) is small.",
    "Stability in sorting means equal elements retain their relative input order.",
    "Insertion sort is incredibly fast for small or nearly sorted arrays.",

    // 8) Matrix
    "A 2D matrix can be flattened into a 1D array using the formula: index = row * cols + col.",
    "To transpose a square matrix in-place, swap matrix[i][j] with matrix[j][i].",
    "Rotating a matrix 90 degrees is just a transpose followed by reversing each row.",
    "You can search a row-wise and column-wise sorted matrix in O(R + C) time.",
    "Spiral traversal requires carefully updating four boundaries: top, bottom, left, and right.",

    // 9) Hashing
    "HashMaps provide average O(1) time complexity for search, insert, and delete operations.",
    "Open Addressing and Chaining are the two main ways to handle hash collisions.",
    "To find a subarray with zero sum, use a HashSet to keep track of prefix sums.",
    "A sliding window combined with a HashMap is a classic way to count distinct elements in a window.",
    "Always choose a good hash function to minimize collisions and maintain O(1) performance.",

    // 10) Strings
    "In Java and C#, Strings are immutable. Use StringBuilder for heavy string manipulations.",
    "Anagrams can be checked efficiently by comparing character frequency arrays.",
    "Rabin-Karp uses a rolling hash to find pattern matches in O(N+M) average time.",
    "The KMP algorithm uses an LPS (Longest Prefix Suffix) array to avoid redundant character comparisons.",
    "To find the longest common span with the same sum in two binary arrays, compute their difference array.",

    // 11) Linked List
    "Floyd’s Cycle Finding Algorithm (Tortoise and Hare) detects loops in O(N) time and O(1) space.",
    "To find the middle of a Linked List in one pass, move the fast pointer by 2 and slow pointer by 1.",
    "Reversing a Linked List requires carefully updating three pointers: prev, curr, and next.",
    "A Doubly Linked List allows O(1) deletions if you have the pointer to the node.",
    "Clone a linked list with random pointers by interleaving new nodes between original nodes.",

    // 12) Stack
    "Stacks follow LIFO (Last In, First Out). Perfect for matching parentheses or undo operations.",
    "The 'Next Greater Element' problem can be solved in O(N) using a Monotonic Stack.",
    "Infix, Prefix, and Postfix expressions can all be evaluated efficiently using Stacks.",
    "To design a Stack that gets the minimum element in O(1) time, keep a secondary stack of minimums.",
    "The Largest Rectangular Area in a Histogram is a classic Monotonic Stack problem.",

    // 13) Queue & Deque
    "Queues follow FIFO (First In, First Out). Excellent for scheduling and BFS traversal.",
    "A Circular Queue prevents wasted space at the front of the array after dequeuing.",
    "You can implement a Queue using two Stacks. Amortized time for operations is O(1).",
    "A Deque (Double Ended Queue) allows insertion and deletion at both ends in O(1) time.",
    "The Sliding Window Maximum problem is elegantly solved in O(N) using a Deque.",

    // 14) Tree
    "Inorder traversal of a Binary Search Tree always yields sorted elements.",
    "Level Order Traversal is essentially Breadth-First Search (BFS) using a Queue.",
    "The height of a Binary Tree is the longest path from the root to a leaf node.",
    "The Lowest Common Ancestor (LCA) in a Binary Tree can be found with a single post-order traversal.",
    "To serialize a tree to a string, pre-order traversal with a special marker for nulls works perfectly.",

    // 15) Binary Search Tree
    "A BST guarantees O(log N) search on average, but can degrade to O(N) if unbalanced.",
    "Self-balancing BSTs like AVL or Red-Black Trees strictly maintain O(log N) height.",
    "To find the K-th smallest element in a BST, do an Inorder traversal.",
    "The 'Ceiling' of a key in a BST is the smallest node that is greater than or equal to the key.",
    "In Java, TreeMap and TreeSet are implemented using Red-Black Trees.",

    // 16) Heap
    "A Min-Heap allows accessing the minimum element in O(1) and extracting it in O(log N).",
    "Building a heap from an array takes O(N) time using the bottom-up heapify method.",
    "Priority Queues are fundamentally implemented using Heaps.",
    "To find the K largest elements in a stream, maintain a Min-Heap of size K.",
    "Finding the median of a data stream requires balancing a Max-Heap and a Min-Heap.",

    // 17) Graph
    "Adjacency Lists are preferred for sparse graphs, while Matrices are better for dense graphs.",
    "Breadth-First Search (BFS) guarantees the shortest path in an unweighted graph.",
    "Depth-First Search (DFS) is naturally recursive and great for finding connected components.",
    "Topological Sorting only works on Directed Acyclic Graphs (DAGs).",
    "Dijkstra's Algorithm fails if the graph has negative weight edges. Use Bellman-Ford instead.",
    "Kruskal's Algorithm uses a Disjoint Set to find the Minimum Spanning Tree.",

    // 18) Greedy
    "Greedy algorithms make the locally optimal choice at each step. They don't always yield the global optimum!",
    "The Activity Selection Problem is a classic Greedy problem: always pick the activity that finishes earliest.",
    "Fractional Knapsack can be solved greedily by sorting items by their value-to-weight ratio.",
    "Huffman Coding uses a Greedy approach and a Min-Heap to generate optimal prefix codes.",
    "Job Sequencing with Deadlines uses Greedy approach: sort by profit and schedule as late as possible.",

    // 19) Backtracking
    "Backtracking is just DFS with a pruning mechanism to abandon invalid paths early.",
    "The N-Queen problem uses Backtracking to safely place queens one by one.",
    "Sudoku solvers rely on Backtracking to try a number and backtrack if it leads to an invalid board.",
    "Rat in a Maze explores all paths using Backtracking and a visited matrix.",
    "Whenever you 'do' a move in Backtracking, remember to 'undo' it after the recursive call!",

    // 20) Dynamic Programming
    "Dynamic Programming is just recursion with memoization (caching overlapping subproblems).",
    "Tabulation is the bottom-up approach to DP. Memoization is the top-down approach.",
    "The 0-1 Knapsack problem is a fundamental DP pattern. You either take the item or leave it.",
    "Longest Common Subsequence (LCS) helps in solving many string-related DP problems.",
    "The Longest Increasing Subsequence (LIS) can be optimized to O(N log N) using Binary Search.",

    // 21) Trie
    "A Trie (Prefix Tree) is incredibly fast for dictionary lookups and prefix matching.",
    "Searching for a word of length L in a Trie takes O(L) time, completely independent of the dictionary size.",
    "Tries are widely used for implementing auto-complete functionality.",
    "To count distinct rows in a binary matrix, insert them into a Trie. The number of unique paths is the answer.",
    "A Trie can use significant memory if the alphabet size is large and the tree is dense.",

    // 22) Segment Tree & Disjoint Set
    "Segment Trees allow range queries (like sum, min, max) and point updates both in O(log N) time.",
    "A Segment Tree for an array of size N takes roughly 4N space.",
    "Disjoint Set (Union-Find) is perfect for grouping elements and finding connected components.",
    "With Path Compression and Union by Rank, Disjoint Set operations take nearly O(1) time.",
    "Kruskal's Minimum Spanning Tree heavily relies on the Disjoint Set data structure."
  ];
}
