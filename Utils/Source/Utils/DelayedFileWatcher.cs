using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Timers;

namespace Utils
{
    public class DelayedFileWatcher
    {
        private readonly List<string> _changedFiles = new List<string>();
        private readonly string _exclude;
        private readonly Timer _timer;

        public DelayedFileWatcher(string path, string exclude = "", int interval = 500)
        {
            _exclude = exclude.ToLower();
            var watcher = new FileSystemWatcher
            {
                Path = path,
                IncludeSubdirectories = true,
                EnableRaisingEvents = true
            };
            watcher.Changed += OnWatcherChanged;

            _timer = new Timer
            {
                Interval = interval,
                AutoReset = false
            };
            _timer.Elapsed += OnTimerOnElapsed;
        }

        private void OnWatcherChanged(object sender, FileSystemEventArgs e)
        {
            string file = e.FullPath;
            if (!string.IsNullOrEmpty(_exclude) && file.ToLower().Contains(_exclude))
                return;
            if (!_changedFiles.Contains(file))
                _changedFiles.Add(file);
            _timer.Stop();
            _timer.Start();
        }

        private void OnTimerOnElapsed(object sender, ElapsedEventArgs e)
        {
            if (!_changedFiles.Any())
                return;
            string[] changedFiles = _changedFiles.ToArray();
            _changedFiles.Clear();
            if (Changed != null)
            {
                Changed(this, new DelayedFileWatcherEventArgs(changedFiles));
            }
        }

        public event EventHandler<DelayedFileWatcherEventArgs> Changed;
    }
}