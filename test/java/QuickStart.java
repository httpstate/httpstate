import com.httpstate.HttpState;

public class QuickStart {
  public static void main(String[] args) throws Exception {
    new HttpState("58bff2fcbeb846958f36e7ae5b8a75b0")
      .On("change", data -> System.out.println(java.time.Instant.now().toString() + " data " + data));

    // Not needed per se, only meant to keep the script alive
    Thread.sleep(Long.MAX_VALUE);
  }
}
