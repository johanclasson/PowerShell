namespace Utils
{
    internal static class Program
    {
        private static void Main(string[] args)
        {
            var w = new DelayedFileWatcher(@"C:\dev\PowerShell","\\.git");
            w.Changed += (sender, eventArgs) => System.Console.WriteLine(string.Join(",",eventArgs.Files));
            System.Console.ReadKey();
        }
    }
}