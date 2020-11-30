/*
 *  Registering an event
 *  EventDispatcher.OnRefresh += EventDispatcher_OnRefresh;
 * 
 *  protected void EventDispatcher_OnRefresh(object sender, RefreshEventArgs e)
 *  {
 *   do something
 *  }
 * 
 *  Raise an event
 *  EventDispatcher.RaiseEvent(new object(), new RefreshEventArgs(Event.REFRESH_CONTACTS));
*/

using System;

namespace ODISMember.Helpers.UIHelpers
{   
    public class RefreshEventArgs : EventArgs
    {
        public int EventId { get; set; }
		public string GroupId {	get; set; }

        public RefreshEventArgs(int eventId) : base()
        {
			EventId = eventId;
        }
    }
    public static class EventDispatcher
    {
        public static event EventHandler<RefreshEventArgs> OnRefresh;

        public static void RaiseEvent(object sender, RefreshEventArgs args)
        {
            if (OnRefresh != null)
            {   
                OnRefresh.Invoke(sender,args);
            }
        }

        /// <summary>
        /// Removes all delegates attached to the OnRefresh event handler        
        /// </summary>
        public static void RemoveAllDelegates()
        {
            OnRefresh = null;
        }

        /// <summary>
        /// Determines whether [is delegate exists] [the specified event handler].
        /// </summary>
        /// <param name="eventHandler">The event handler.</param>
        /// <returns>True if delegate already attached, false if delegate not exists already
        /// </returns>
        public static bool IsDelegateExists(EventHandler<RefreshEventArgs> eventHandler)
        {
            if (OnRefresh != null && OnRefresh.GetInvocationList() != null)
            {
                for (int i = 0, iCount = OnRefresh.GetInvocationList().Length; i < iCount; i++)
                {
                    Delegate item = OnRefresh.GetInvocationList()[i];

                    if (item.Target != null && eventHandler.Target != null && item.Target.ToString() == eventHandler.Target.ToString())
                    {
                        return true;
                    }
                }
            }
            return false;            
        }
    }
}

