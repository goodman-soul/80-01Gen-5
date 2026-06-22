<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import type { PageData } from './$types';
	import { User, Lock, Mail, AlertCircle } from 'lucide-svelte';

	export let data: PageData;

	let email = '';
	let password = '';
	let loading = false;
	let error = '';
	let role: 'parent' | 'therapist' | 'admin' = 'parent';

	$: nextUrl = $page.url.searchParams.get('next') || '/';

	async function handleLogin(e: SubmitEvent) {
		e.preventDefault();
		loading = true;
		error = '';

		const { error: authError } = await data.supabase.auth.signInWithPassword({
			email,
			password
		});

		if (authError) {
			error = authError.message;
			loading = false;
			return;
		}

		loading = false;
		if (nextUrl !== '/') {
			await goto(nextUrl);
		}
	}
</script>

<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-50 to-blue-100 px-4 py-12">
	<div class="w-full max-w-md">
		<div class="text-center mb-8">
			<div class="w-16 h-16 bg-primary-500 rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-lg">
				<User class="w-8 h-8 text-white" />
			</div>
			<h1 class="text-3xl font-bold text-gray-900">儿童康复训练系统</h1>
			<p class="text-gray-500 mt-2">家庭作业管理平台</p>
		</div>

		<div class="card p-8">
			<h2 class="text-xl font-semibold text-gray-900 mb-6">登录账号</h2>

			{#if error}
				<div class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg flex items-center text-red-600 text-sm">
					<AlertCircle class="w-5 h-5 mr-2 flex-shrink-0" />
					{error}
				</div>
			{/if}

			<form on:submit={handleLogin} class="space-y-5">
				<div>
					<label class="label" for="email">邮箱</label>
					<div class="relative">
						<Mail class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
						<input
							id="email"
							type="email"
							bind:value={email}
							class="input pl-10"
							placeholder="请输入邮箱"
							required
						/>
					</div>
				</div>

				<div>
					<label class="label" for="password">密码</label>
					<div class="relative">
						<Lock class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
						<input
							id="password"
							type="password"
							bind:value={password}
							class="input pl-10"
							placeholder="请输入密码"
							required
						/>
					</div>
				</div>

				<div>
					<label class="label" for="role-parent">登录身份</label>
					<div class="grid grid-cols-3 gap-2">
						<button
							id="role-parent"
							type="button"
							on:click={() => (role = 'parent')}
							class="px-4 py-2 rounded-lg text-sm font-medium transition-colors border {
								role === 'parent'
									? 'bg-primary-500 text-white border-primary-500'
									: 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
							}"
						>
							家长
						</button>
						<button
							type="button"
							on:click={() => (role = 'therapist')}
							class="px-4 py-2 rounded-lg text-sm font-medium transition-colors border {
								role === 'therapist'
									? 'bg-primary-500 text-white border-primary-500'
									: 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
							}"
						>
							治疗师
						</button>
						<button
							type="button"
							on:click={() => (role = 'admin')}
							class="px-4 py-2 rounded-lg text-sm font-medium transition-colors border {
								role === 'admin'
									? 'bg-primary-500 text-white border-primary-500'
									: 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
							}"
						>
							管理员
						</button>
					</div>
					<p class="text-xs text-gray-500 mt-2">提示：身份仅用于演示切换，实际由系统分配</p>
				</div>

				<button type="submit" class="btn btn-primary w-full" disabled={loading}>
					{loading ? '登录中...' : '登录'}
				</button>
			</form>

			<div class="mt-6 p-4 bg-gray-50 rounded-lg">
				<p class="text-xs font-medium text-gray-700 mb-2">演示账号（需在 Supabase 创建）：</p>
				<div class="text-xs text-gray-600 space-y-1">
					<p>家长：parent@demo.com / Parent123!</p>
					<p>治疗师：therapist@demo.com / Therapist123!</p>
					<p>管理员：admin@demo.com / Admin123!</p>
				</div>
			</div>
		</div>
	</div>
</div>
