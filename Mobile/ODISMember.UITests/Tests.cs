using System;
using System.IO;
using System.Linq;
using NUnit.Framework;
using Xamarin.UITest;
using Xamarin.UITest.Android;
using Xamarin.UITest.Queries;

namespace ODISMember.UITests
{
	[TestFixture(Platform.Android)]
	//[TestFixture(Platform.iOS)]
	public class Tests
	{
		IApp app;
		Platform platform;

		const string MEMBER_LOGIN = "btnMemberLogin";
		const string TITLE = "Pinnacle";
		const string JOIN_NOW = "btnJoinNow";
		const string GUEST_REGISTRATION = "btnGuestRegistration";
		const string SIGN_IN = "btnSignIn";

		public Tests(Platform platform)
		{
			this.platform = platform;
		}

		[SetUp]
		public void BeforeEachTest ()
		{
			app = AppInitializer.StartApp(platform);
		}

		[Test]
		public void _1_LaunchScreen ()
		{
			//var file = app.Screenshot ("First screen.");
			//Check for title, three buttons.
			var title = app.WaitForElement (c => c.Marked (TITLE));
			var btnMemberLogin = app.WaitForElement (c => c.Marked (MEMBER_LOGIN));
			var btnJoinNow = app.WaitForElement (c => c.Marked (JOIN_NOW));
			var btnGuestRegistration = app.WaitForElement (c => c.Marked (GUEST_REGISTRATION));

			Assert.IsNotNull (title);
			Assert.IsNotNull (btnMemberLogin);
			Assert.IsNotNull (btnJoinNow);
			Assert.IsNotNull (btnGuestRegistration);
		}

		[Test]
		public void _2_MemberLogin()
		{
			var qMemberLogin = new Func<AppQuery,AppQuery> (c => c.Marked (MEMBER_LOGIN));
			var qSignIn = new Func<AppQuery,AppQuery> (c => c.Marked (SIGN_IN));

			var btnMemberLogin = app.WaitForElement (qMemberLogin);
			Assert.IsNotNull (btnMemberLogin);

			app.Tap (qMemberLogin);

			var signIn = app.WaitForElement (qSignIn);

			Assert.IsNotNull (signIn);
		}
		[Test]
		public void _3_JoinNow()
		{
			var qJoinNow = new Func<AppQuery,AppQuery> (c => c.Marked (JOIN_NOW));
			var qJoinPMC = new Func<AppQuery,AppQuery> (c => c.Marked ("Join PMC"));

			var btnJoinNow= app.WaitForElement (qJoinNow);
			Assert.IsNotNull (btnJoinNow);

			app.Tap (qJoinNow);

			var signIn = app.WaitForElement (qJoinPMC);
			Assert.IsNotNull (signIn);
		}
	}
}

