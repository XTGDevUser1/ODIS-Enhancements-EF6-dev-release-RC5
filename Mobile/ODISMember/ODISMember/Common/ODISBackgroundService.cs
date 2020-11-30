using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace ODISMember.Common
{
    public class ODISBackgroundService
    {
        CancellationTokenSource _cancellationToken;
        // Queue
        private static List<Action> _tasks = new List<Action>();
        private static ODISBackgroundService _instance;

        Task bgTask = null;
        static bool isBusy = false;

        private ODISBackgroundService()
        {
            _cancellationToken = new CancellationTokenSource();
        }

        public static ODISBackgroundService GetInstance()
        {
            if (_instance == null)
            {
                _instance = new ODISBackgroundService();
            }
            return _instance;
        }
        public void StartService()
        {
            lock (this)
            {
                bgTask = Task.Factory.StartNew(() =>
                {
                    ProcessQueue();
                }, _cancellationToken.Token);
            }
        }

        private void ProcessQueue()
        {
            while (_tasks.Count > 0)
            {   
                _cancellationToken.Token.ThrowIfCancellationRequested();
                if (_tasks.Count > 0)
                {
                    var firstItem = _tasks[0];
                    try
                    {
                        firstItem();
                        if (_tasks.Count > 0)
                        {
                            _tasks.RemoveAt(0);
                        }
                    }
                    catch (SQLite.Net.SQLiteException sqlEx)
                    {
                        // Retry the operation assuming that the SQLLite database got locked up.
                        Task.Delay(250).Wait();
                    }
                }
            }
            isBusy = false;
        }

        public void StopService()
        {
            _cancellationToken.Cancel();

            try
            {
                bgTask.Wait();
            }
            catch (AggregateException)
            {
                // Do nothing
            }
        }


        public void Enqueue(Action todo)
        {   
            lock (_tasks)
            {
                _tasks.Add(todo);
                if (_tasks.Count > 0 && !isBusy)
                {
                    isBusy = true;
                    _cancellationToken = new CancellationTokenSource();
                    bgTask = null;
                    StartService();
                }
            }
        }
    }
}
