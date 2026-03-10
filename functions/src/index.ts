import {setGlobalOptions} from "firebase-functions";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onDocumentCreated} from "firebase-functions/v2/firestore"; // [추가] Firestore 트리거
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ 
  region: "asia-northeast3", 
  maxInstances: 10 
});

/**
 * 1. 테이블 아웃 알림 (FCM)
 * 경로: company/{companyId}/tables/{tableId}/history/{historyId} 문서 생성 시 실행
 */
export const sendTableOutNotification = onDocumentCreated(
  "company/{companyid}/tables/{tableid}/history/{historyid}",
  async (event) => {
    console.log("🔥 1. 함수 시작! 트리거 감지됨.");

    const data = event.data?.data();
    if (!data) {
      console.log("❌ 2. 데이터 없음 (종료)");
      return;
    }

    // 경로에 있는 companyid (예: testcafe)
    const companyid = event.params.companyid; 
    console.log(`🧐 3. 타겟 업체 ID: ${companyid}`);

    // [핵심] Firestore에서 companyid가 정확히 일치하는 직원 찾기
    const usersSnap = await db.collection("users")
      .where("companyid", "==", companyid) 
      .get();

    console.log(`👥 4. 검색된 직원 수: ${usersSnap.size}명`);

    const tokens: string[] = [];
    usersSnap.forEach((doc) => {
      const userData = doc.data();
      if (userData.fcmtoken) {
        tokens.push(userData.fcmtoken);
      }
    });

    console.log(`📨 5. 수집된 토큰 개수: ${tokens.length}개`);

    if (tokens.length === 0) {
      console.log("⚠️ 6. 보낼 토큰이 없음! (종료)");
      console.log("   -> 힌트: users 컬렉션의 companyid와 위 타겟 ID가 대소문자까지 똑같은지 확인하세요.");
      return;
    }

    // 알림 메시지 구성
    const message = {
      notification: {
        title: "테이블 아웃 알림",
        body: `${data.tablename}번 테이블이 아웃되었습니다.`,
      },
      android: {
    priority: "high" as const,
    notification: {
      channelId: "high_importance_channel", // AndroidManifest.xml에 넣었던 그 ID
      priority: "high" as const,
      defaultSound: true,
      visibility: "public" as const
    }
  },
      tokens: tokens,
    };

    // 전송
    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`✅ 7. 전송 완료! 성공: ${response.successCount}, 실패: ${response.failureCount}`);
    } catch (error) {
      console.error("❌ 8. 전송 중 에러 발생:", error);
    }
  }
);

/**
 * 2. 매일 오전 11시(한국 시간) 데이터 리셋
 */
export const dailyDataReset = onSchedule({
  schedule: "0 11 * * *",
  timeZone: "Asia/Seoul",
}, async (_event) => {
  const companiesSnap = await db.collection("company").get();

  for (const companyDoc of companiesSnap.docs) {
    const tablesRef = db.collection("company").doc(companyDoc.id).collection("tables");
    const tablesSnap = await tablesRef.get();
    const batch = db.batch();

    for (const tableDoc of tablesSnap.docs) {
      // 필드 초기화
      batch.update(tableDoc.ref, {
        status: "available",
        customer: "",
        phonenumber: "",
        staff: "",
        bottle: "",
        remark: "",
        reservationTime: "",
        persons: 0,
        groupid: admin.firestore.FieldValue.delete(),
        ismaster: admin.firestore.FieldValue.delete(),
        mastertablenumber: admin.firestore.FieldValue.delete(),
        updatedat: admin.firestore.FieldValue.serverTimestamp(),
      });

      // [중요] 여기서는 히스토리를 '삭제'만 하므로 sendTableOutNotification이 실행되지 않음
      const historySnap = await tableDoc.ref.collection("history").get();
      historySnap.forEach((hDoc) => {
        batch.delete(hDoc.ref);
      });
    }

    try {
      await batch.commit();
      console.log(`${companyDoc.id} 업체 리셋 완료`);
    } catch (error) {
      console.error(`${companyDoc.id} 오류:`, error);
    }
  }
});