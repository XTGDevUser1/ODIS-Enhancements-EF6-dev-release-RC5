using System;
using System.IO;
using System.Linq;
using NUnit.Framework;
using Xamarin.UITest;
using Xamarin.UITest.Queries;

namespace Mobile.UITest
{
    [TestFixture(Platform.Android)]
    [TestFixture(Platform.iOS)]
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
        public void BeforeEachTest()
        {
            app = AppInitializer.StartApp(platform);
        }
        [Test]
        public void ListPageElements()
        {
            app.Repl();
        }

        [Test]
        public void _2_MemberLogin()
        {
            app.EnterText(c => c.Marked("Username"), "Pmctest");
            app.EnterText(c => c.Marked("Password"), "Password1");
            var btnForgotPassword = app.WaitForElement(c => c.Marked("FORGOT PASSWORD? /"));
            var btnForgotUsername = app.WaitForElement(c => c.Marked(" FORGOT USERNAME?"));
            var btnSignIn = app.WaitForElement(c => c.Marked("SIGN IN"));
            var btnRegister= app.WaitForElement(c => c.Marked("REGISTER"));
            var btnJoin = app.WaitForElement(c => c.Marked("JOIN"));
            var btnTerms = app.WaitForElement(c => c.Marked("TERMS & CONDITIONS"));
            Assert.IsNotNull(btnForgotPassword);
            Assert.IsNotNull(btnForgotUsername);
            Assert.IsNotNull(btnSignIn);
            Assert.IsNotNull(btnRegister);
            Assert.IsNotNull(btnJoin);
            Assert.IsNotNull(btnTerms);
            app.Tap(c => c.Marked("SIGN IN"));
            var btnNotifyMe = app.WaitForElement(c => c.Marked("NOTIFY ME"), timeout: TimeSpan.FromSeconds(180));
            Assert.IsNotNull(btnNotifyMe);
            _3_WalhthroughScreens();
        }
        [Test]
        public void _3_WalhthroughScreens()
        {
            app.Tap(c => c.Marked("NOTIFY ME"));
            var btnGotIt = app.WaitForElement(c => c.Marked("OK, GOT IT"), timeout: TimeSpan.FromSeconds(180));
            Assert.IsNotNull(btnGotIt);
            app.Tap(c => c.Marked("OK, GOT IT"));
            var title = app.WaitForElement(c => c.Marked("Welcome"), timeout: TimeSpan.FromSeconds(180));
            Assert.IsNotNull(title);
            _4_HomePage();
        }
        public void _4_HomePage()
        {

            
        }
    }
}

