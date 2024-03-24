import shouldBehaveLikeOwner from "./view/owner";

export function shouldBehaveLikeLockContract(): void {
  describe("View Functions", function () {
    describe("#owner", function () {
      shouldBehaveLikeOwner();
    });
  });
}
