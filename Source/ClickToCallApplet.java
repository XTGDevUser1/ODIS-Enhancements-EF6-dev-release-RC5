import java.applet.Applet;
import java.awt.Graphics;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringWriter;

public class ClickToCallApplet extends Applet {

	protected String _val;
	protected static String _error;

	public void init() {

		String paramDeviceRegistryPath = getParameter("DeviceRegistryPath");
		DEVICE_REGISTRY_PATH = REGQUERY_UTIL + "\"" + paramDeviceRegistryPath
				+ "\"" + " /v HostName";
		_val = getDeviceNameFromRegistry();
	}

	/**
	 * @return The Device name
	 */
	public String getDeviceName() {
		
		return _val;

	}

	public void paint(Graphics g) {
		//_val = getDeviceNameFromRegistry();
		if(_val == null)
		{
			g.drawString(_error, 10, 10);
		}
		else
		{
			g.drawString(_val, 10, 10);
		}
	}

	private static final String REGQUERY_UTIL = "reg query ";
	private static final String REGSTR_TOKEN = "REG_SZ";
	private static final String REGDWORD_TOKEN = "REG_DWORD";

	private static String DEVICE_REGISTRY_PATH = "";

	/**
	 * Read the registry key for device name
	 * @return
	 */
	public static String getDeviceNameFromRegistry() {
		try {
			
			
			Process process = Runtime.getRuntime().exec(DEVICE_REGISTRY_PATH);
			StreamReader reader = new StreamReader(process.getInputStream());

			reader.start();
			process.waitFor();
			reader.join();

			String result = reader.getResult();
			int p = result.indexOf(REGSTR_TOKEN);
			_error = DEVICE_REGISTRY_PATH;
			if (p == -1)
				return null;

			return result.substring(p + REGSTR_TOKEN.length()).trim();
		} catch (Exception e) {
			_error = e.getMessage();
			return null;
		}
	}

	/**
	 * @author kbanda
	 * Static utility class for stream management.
	 */
	static class StreamReader extends Thread {
		private InputStream is;
		private StringWriter sw;

		StreamReader(InputStream is) {
			this.is = is;
			sw = new StringWriter();
		}

		public void run() {
			try {
				int c;
				while ((c = is.read()) != -1)
					sw.write(c);
			} catch (IOException e) {
				;
			}
		}

		String getResult() {
			return sw.toString();
		}
	}

}
