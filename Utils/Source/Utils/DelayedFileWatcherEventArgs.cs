using System;

namespace Utils
{
    public class DelayedFileWatcherEventArgs : EventArgs
    {
        public DelayedFileWatcherEventArgs(string[] files)
        {
            Files = files;
        }

        public string[] Files { get; private set; }
    }
}